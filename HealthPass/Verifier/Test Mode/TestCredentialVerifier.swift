//
//  TestCredentialVerifier.swift
//  Verifier
//
//  Created by John Martino on 2021-09-14.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit
import QRCoder
import VerifiableCredential
import VerificationEngine
import PromiseKit

class TestCredentialVerifier {
    
    var verifiableObject: VerifiableObject!
    var verifyEngine: VerifyEngine!
    
    var specificationConfiguration: SpecificationConfiguration?

    internal func isKnown() -> Promise<Void> {
        return Promise { resolver in
         
            let supportedTypes = DisplayService().getSupportedTypes()
            
            do {
                if (try self.verifyEngine.isKnown(supportedTypes)) {
                    resolver.fulfill_()
                } else {
                    resolver.reject(NSError.credentialUnknown)
                }
            } catch {
                resolver.reject(error)
            }
        }
    }
    
    internal func isNotRevoked() -> Promise<Void> {
        return Promise { resolver in
            guard verifiableObject.type == .IDHP || verifiableObject.type == .GHP || verifiableObject.type == .VC else {
                resolver.fulfill_()
                return
            }
            
            guard let did = verifiableObject.credential?.id else {
                resolver.reject(NSError.credentialRevokeNoProperties)
                return
            }
            
            CredentialService().getRevokeStatus(for: did) { result in
                switch result {
                case .success(let revokeStatus):
                    guard let revokePayload = revokeStatus["payload"] as? [String : Any] else {
                        resolver.fulfill_()
                        return
                    }
                    
                    guard let isRevoked = self.isRevoked(payload: revokePayload) else {
                        resolver.fulfill_()
                        return
                    }
                    
                    if isRevoked {
                        resolver.reject(NSError.credentialRevoked)
                    } else {
                        resolver.fulfill_()
                    }
                    
                case .failure:
                    resolver.fulfill_()
                }
            }
        }
    }
    
    private func isRevoked(payload: [String : Any]) -> Bool? {
        guard let exists = payload["exists"] as? Int else {
            return nil
        }
        
        return (exists == 1)
    }
    
    internal func isValidSignature() -> Promise<Void> {
        return Promise { resolver in
            if verifiableObject.type == .IDHP || verifiableObject.type == .GHP || verifiableObject.type == .VC, let credential = verifiableObject.credential {
                self.getPublicKey(for: credential, completion: { issuer in
                    
                    guard let issuer = issuer else {
                        resolver.reject(NSError.credentialSignatureUnavailableKey)
                        return
                    }
                    
                    self.verifyEngine.issuer = issuer
                    
                    do {
                        if (try self.verifyEngine.hasValidSignature()) {
                            resolver.fulfill_()
                        } else {
                            resolver.reject(NSError.credentialSignatureFailed)
                        }
                    } catch {
                        resolver.reject(error)
                    }
                    
                })
            } else if verifiableObject.type == .SHC, let jws = verifiableObject.jws {
                self.getPublicKey(for: jws, completion: { jwkKeys in
                    
                    guard let jwkKeys = jwkKeys, !(jwkKeys.isEmpty) else {
                        resolver.reject(NSError.credentialSignatureUnavailableKey)
                        return
                    }
                    
                    self.verifyEngine.jwkSet = jwkKeys
                    
                    do {
                        if (try self.verifyEngine.hasValidSignature()) {
                            resolver.fulfill_()
                        } else {
                            resolver.reject(NSError.credentialSignatureFailed)
                        }
                    } catch {
                        resolver.reject(error)
                    }
                })
            } else if verifiableObject.type == .DCC, let cose = verifiableObject.cose {
                self.getPublicKey(for: cose, completion: { issuerKeys in
                    guard let issuerKeys = issuerKeys, !(issuerKeys.isEmpty) else {
                        resolver.reject(NSError.credentialSignatureUnavailableKey)
                        return
                    }
                    
                    self.verifyEngine.issuerKeys = issuerKeys
                    
                    do {
                        if (try self.verifyEngine.hasValidSignature()) {
                            resolver.fulfill_()
                        } else {
                            resolver.reject(NSError.credentialSignatureFailed)
                        }
                    } catch {
                        resolver.reject(error)
                    }
                    
                })
            } else {
                resolver.reject(NSError.credentialSignatureNoProperties)
            }
            
        }
    }
    
    
    internal func doesMatchRules() -> Promise<Void> {
        return Promise { resolver in
            if let rules = RuleService().getRule(for: verifiableObject.type), !(rules.isEmpty) {
                let rulesResponse = try self.verifyEngine.doesMatchRules(rules: rules)
                guard let result = rulesResponse.result else {
                    resolver.fulfill_()
                    self.fallbackRules(with: resolver)
                    return
                }
                
                if (result) {
                    resolver.fulfill_()
                } else {
                    resolver.reject(NSError.credentialRules)
                }
                
            } else {
                resolver.fulfill_()
            }
        }
    }
    
    private func fallbackRules(with resolver: Resolver<Void>) {
        guard let rules = RuleService().getRule(for: .VC), !(rules.isEmpty) else {
            resolver.fulfill_()
            return
        }
        
        guard let rulesResponse = try? self.verifyEngine.doesMatchRules(rules: rules) else {
            resolver.fulfill_()
            return
        }
       
        if let result = rulesResponse.result, (result) {
            resolver.fulfill_()
        } else {
            resolver.reject(NSError.credentialRules)
        }
    }
    
}

extension TestCredentialVerifier {
    
    internal func isKnown(with verifierConfiguration: VerifierConfiguration) -> Promise<SpecificationConfiguration> {
        return Promise { resolver in
            
            guard var specificationConfigurations = verifierConfiguration.specificationConfigurations else {
                resolver.reject(NSError.credentialUnknown)
                return
            }
            
            verifierConfiguration.disabledSpecifications?.forEach { disabledConfiguration in
                specificationConfigurations = specificationConfigurations.filter({ $0.id != disabledConfiguration.id })
            }
            
            for configuration in specificationConfigurations {
                if let rule = configuration.classifierRule,
                    let rulesResponse = try? self.verifyEngine.doesMatchRules(rules: [rule]),
                    let result = rulesResponse.result, result {
                    self.specificationConfiguration = configuration
                    resolver.fulfill(configuration)
                    return
                }
            }
            
            resolver.reject(NSError.credentialUnknown)
            return
        }
    }
    
    internal func isNotRevoked(with specificationConfiguration: SpecificationConfiguration? = nil) -> Promise<SpecificationConfiguration?> {
        self.specificationConfiguration = specificationConfiguration
        
        return Promise { resolver in
            guard verifiableObject?.type == .IDHP || verifiableObject?.type == .GHP || verifiableObject?.type == .VC else {
                resolver.fulfill(specificationConfiguration)
                return
            }
            
            guard let did = verifiableObject?.credential?.id else {
                resolver.reject(NSError.credentialRevokeNoProperties)
                return
            }
            
            CredentialService().getRevokeStatus(for: did) { result in
                switch result {
                case .success(let revokeStatus):
                    guard let revokePayload = revokeStatus["payload"] as? [String : Any] else {
                        resolver.fulfill(specificationConfiguration)
                        return
                    }
                    
                    guard let isRevoked = self.isRevoked(payload: revokePayload) else {
                        resolver.fulfill(specificationConfiguration)
                        return
                    }
                    
                    if isRevoked {
                        resolver.reject(NSError.credentialRevoked)
                    } else {
                        resolver.fulfill(specificationConfiguration)
                    }
                    
                case .failure(let error):
                    resolver.fulfill(specificationConfiguration)
                }
            }
        }
    }

    internal func isValidSignature(with specificationConfiguration: SpecificationConfiguration? = nil) -> Promise<SpecificationConfiguration?> {
        self.specificationConfiguration = specificationConfiguration
        
        return Promise { resolver in
            guard let verifiableObject = self.verifiableObject else {
                resolver.reject(NSError.credentialSignatureNoProperties)
                return
            }
            
            if verifiableObject.type == .IDHP || verifiableObject.type == .GHP || verifiableObject.type == .VC, let credential = verifiableObject.credential {
                self.getPublicKey(for: credential, completion: { issuer in
                    
                    guard let issuer = issuer else {
                        resolver.reject(NSError.credentialSignatureUnavailableKey)
                        return
                    }
                    
                    self.verifyEngine.issuer = issuer
                    
                    do {
                        if (try self.verifyEngine.hasValidSignature()) {
                            resolver.fulfill(specificationConfiguration)
                        } else {
                            resolver.reject(NSError.credentialSignatureFailed)
                        }
                    } catch {
                        resolver.reject(error)
                    }
                    
                })
            } else if verifiableObject.type == .SHC, let jws = verifiableObject.jws {
                self.getPublicKey(for: jws, completion: { jwkKeys in
                    
                    guard let jwkKeys = jwkKeys, !(jwkKeys.isEmpty) else {
                        resolver.reject(NSError.credentialSignatureUnavailableKey)
                        return
                    }
                    
                    self.verifyEngine.jwkSet = jwkKeys
                    
                    do {
                        if (try self.verifyEngine.hasValidSignature()) {
                            resolver.fulfill(specificationConfiguration)
                        } else {
                            resolver.reject(NSError.credentialSignatureFailed)
                        }
                    } catch {
                        resolver.reject(error)
                    }
                })
            } else if verifiableObject.type == .DCC, let cose = verifiableObject.cose {
                self.getPublicKey(for: cose, completion: { issuerKeys in
                    guard let issuerKeys = issuerKeys, !(issuerKeys.isEmpty) else {
                        resolver.reject(NSError.credentialSignatureUnavailableKey)
                        return
                    }
                    
                    self.verifyEngine.issuerKeys = issuerKeys
                    
                    do {
                        if (try self.verifyEngine.hasValidSignature()) {
                            resolver.fulfill(specificationConfiguration)
                        } else {
                            resolver.reject(NSError.credentialSignatureFailed)
                        }
                    } catch {
                        resolver.reject(error)
                    }
                    
                })
            } else {
                resolver.reject(NSError.credentialSignatureNoProperties)
            }
            
        }
    }

    internal func doesMatchRules(with specificationConfiguration: SpecificationConfiguration?) -> Promise<SpecificationConfiguration?> {
        self.specificationConfiguration = specificationConfiguration
        
        return Promise { resolver in
            if var rules = specificationConfiguration?.rules, !(rules.isEmpty) {
               
                if let disabledRules = DataStore.shared.currentVerifierConfiguration?.disabledRules?.filter({ $0.specID == specificationConfiguration?.id }), !(disabledRules.isEmpty) {
                    disabledRules.forEach { disabledRule in
                        rules = rules.filter({ $0.id != disabledRule.id })
                    }
                }
                
                
                var valueSet: [ValueSet]?
                if let globalValueSet = DataStore.shared.currentVerifierConfiguration?.valueSets, !(globalValueSet.isEmpty) {
                    valueSet = globalValueSet
                }
                
                let rulesResponse = try self.verifyEngine.doesMatchRules(rules: rules, with: valueSet)
                
                if let result = rulesResponse.result, result {
                    resolver.fulfill(specificationConfiguration)
                } else {
                    resolver.reject(NSError.credentialRules)
                }
            } else {
                resolver.fulfill(specificationConfiguration)
            }
        }
    }
}

extension TestCredentialVerifier {
    
    private func getPublicKey(for credential: Credential, completion: @escaping (_ issuer: Issuer?) -> Void) {
        guard let issuerId = credential.issuer else {
            completion(nil)
            return
        }
        
        //Look for cache
        if let cachedIssuer = DataStore.shared.getIssuer(for: issuerId) {
            completion(cachedIssuer)
            return
        }

        IssuerService().getIssuer(issuerId: issuerId) { result in
            switch result {
            case .success(let json):
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                guard let payload = json["payload"] as? [String: Any] else {
                    completion(nil)
                    return
                }
                
                let issuer = Issuer(value: payload)
                
                DataStore.shared.addNewIssuer(issuer: issuer)
                
                completion(issuer)
                
            case .failure:
                completion(nil)
            }
        }
    }
    
}

extension TestCredentialVerifier {
    
    private func getPublicKey(for jws: JWS, completion: @escaping (_ jwkKeys: [JWK]?) -> Void) {
        guard let payload = jws.payload,
              let issuerIdentifier = payload.iss else {
                  completion(nil)
                  return
              }
        
        //Look for cache
        if let cachedJWKSet = DataStore.shared.getJWKSet(for: issuerIdentifier) {
            let jwkKeys = cachedJWKSet.flatMap({ $0.keys })
            completion(jwkKeys)
            return
        }

        IssuerService().getGenericIssuer(issuerId: issuerIdentifier, type: .SHC) { result in
            switch result {
            case .success(let json):
                guard let payload = json["payload"] as? [[String : Any]], !(payload.isEmpty) else {
                    completion(nil)
                    return
                }

                guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                      let jwkSet = try? JSONDecoder().decode([JWKSet].self, from: data) else {
                          completion(nil)
                          return
                      }
                
                DataStore.shared.addJWKSet(jwkSet: jwkSet)

                let filteredJwkSet = jwkSet.compactMap ({ return ($0.url == issuerIdentifier) ? $0 : nil })
                guard !(filteredJwkSet.isEmpty) else {
                    completion(nil)
                    return
                }
                
                let jwkKeys = filteredJwkSet.flatMap({ $0.keys })
                guard !(jwkKeys.isEmpty) else {
                    completion(nil)
                    return
                }
                
                completion(jwkKeys)
                
            case .failure:
                completion(nil)
            }
        }
    }
    
}

extension TestCredentialVerifier {
    
    private func getPublicKey(for cose: Cose, completion: @escaping (_ issuerKeys: [IssuerKey]?) -> Void) {
        
        guard let keyIdBytes = cose.keyId else {
            completion(nil)
            return
        }
        
        let keyId = keyIdBytes.base64EncodedString()
        
        //Look for cache
        if let cachedIssuerKeys = DataStore.shared.getIssuerKey(for: keyId) {
            completion(cachedIssuerKeys)
            return
        }

        IssuerService().getGenericIssuer(issuerId: keyId, type: .DCC) { result in
            switch result {
            case .success(let json):
                guard let jsonPayload = json["payload"] as? [String : Any],
                      let payload = jsonPayload["payload"] as? [[String : Any]], !(payload.isEmpty) else {
                          completion(nil)
                          return
                      }
                
                guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                      let issuerKeys = try? JSONDecoder().decode([IssuerKey].self, from: data) else {
                          completion(nil)
                          return
                      }
                
                let requiredIssuerKeys = issuerKeys.filter({ $0.kid == keyId })
                
                guard !(requiredIssuerKeys.isEmpty) else {
                    completion(nil)
                    return
                }
                
                completion(requiredIssuerKeys)
                
            case .failure:
                completion(nil)
            }
        }
        
    }
    
    private func trustAnchorKey(for trustAnchor: String) -> SecKey? {
        guard let certData = Data(base64Encoded: trustAnchor),
              let certificate = SecCertificateCreateWithData(nil, certData as CFData),
              let secKey = SecCertificateCopyKey(certificate) else {
                  return nil
              }
        return secKey
    }
    
}

