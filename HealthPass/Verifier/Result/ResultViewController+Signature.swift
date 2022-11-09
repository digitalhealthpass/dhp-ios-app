//
//  ResultViewController+Signature.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import VerifiableCredential
import VerificationEngine
import PromiseKit
import OSLog

extension ResultViewController {
    
    internal func isValidSignature(with specificationConfiguration: SpecificationConfiguration? = nil) -> Promise<SpecificationConfiguration?> {
        self.specificationConfiguration = specificationConfiguration
        
        return Promise { resolver in
            guard let verifiableObject = self.verifiableObject else {
                os_log("isValidSignature - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, "No Verifiable Object")
                resolver.reject(NSError.credentialSignatureNoProperties)
                return
            }
            
            if verifiableObject.type == .IDHP || verifiableObject.type == .GHP || verifiableObject.type == .VC, let credential = verifiableObject.credential {
                self.getPublicKey(for: credential, completion: { issuer in
                    
                    guard let issuer = issuer else {
                        os_log("isValidSignature - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, "No Issuer Object")
                        resolver.reject(NSError.credentialSignatureUnavailableKey)
                        return
                    }
                    
                    self.verifyEngine.issuer = issuer
                    
                    do {
                        if (try self.verifyEngine.hasValidSignature()) {
                            resolver.fulfill(specificationConfiguration)
                        } else {
                            os_log("hasValidSignature - False ", log: OSLog.resultViewControllerOSLog, type: .info)
                            resolver.reject(NSError.credentialSignatureFailed)
                        }
                    } catch {
                        os_log("isValidSignature - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, error.localizedDescription)
                        resolver.reject(error)
                    }
                    
                })
            } else if verifiableObject.type == .SHC, let jws = verifiableObject.jws {
                self.getPublicKey(for: jws, completion: { jwkKeys in
                    
                    guard let jwkKeys = jwkKeys, !(jwkKeys.isEmpty) else {
                        os_log("isValidSignature - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, "No Issuer Object")
                        resolver.reject(NSError.credentialSignatureUnavailableKey)
                        return
                    }
                    
                    self.verifyEngine.jwkSet = jwkKeys
                    
                    do {
                        if (try self.verifyEngine.hasValidSignature()) {
                            resolver.fulfill(specificationConfiguration)
                        } else {
                            os_log("hasValidSignature - False ", log: OSLog.resultViewControllerOSLog, type: .info)
                            resolver.reject(NSError.credentialSignatureFailed)
                        }
                    } catch {
                        os_log("isValidSignature - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, error.localizedDescription)
                        resolver.reject(error)
                    }
                })
            } else if verifiableObject.type == .DCC, let cose = verifiableObject.cose {
                self.getPublicKey(for: cose, completion: { issuerKeys in
                    guard let issuerKeys = issuerKeys, !(issuerKeys.isEmpty) else {
                        os_log("isValidSignature - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, "No Issuer Object")
                        resolver.reject(NSError.credentialSignatureUnavailableKey)
                        return
                    }
                    
                    self.verifyEngine.issuerKeys = issuerKeys
                    
                    do {
                        if (try self.verifyEngine.hasValidSignature()) {
                            resolver.fulfill(specificationConfiguration)
                        } else {
                            os_log("hasValidSignature - False ", log: OSLog.resultViewControllerOSLog, type: .info)
                            resolver.reject(NSError.credentialSignatureFailed)
                        }
                    } catch {
                        os_log("isValidSignature - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, error.localizedDescription)
                        resolver.reject(error)
                    }
                    
                })
            } else {
                resolver.reject(NSError.credentialSignatureNoProperties)
            }
            
        }
    }
    
}

extension ResultViewController {
    
    private func getPublicKey(for credential: Credential, completion: @escaping (_ issuer: Issuer?) -> Void) {
        guard let issuerId = credential.issuer else {
            os_log("getPublicKey - Credential - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, "No issuer properties")
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
                    os_log("getPublicKey - Credential - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, "Unexpected payload")
                    completion(nil)
                    return
                }
                
                let issuer = Issuer(value: payload)
                
                DataStore.shared.addNewIssuer(issuer: issuer)
                
                completion(issuer)
                
            case .failure(let error):
                os_log("getPublicKey - Credential - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, error.localizedDescription)
                completion(nil)
            }
        }
    }
    
}

extension ResultViewController {
    
    private func getPublicKey(for jws: JWS, completion: @escaping (_ jwkKeys: [JWK]?) -> Void) {
        guard let payload = jws.payload,
              let issuerIdentifier = payload.iss else {
                  os_log("getPublicKey - JWS - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, "No issuer properties")
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
                    os_log("getGenericIssuer - JWS - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, "Unexpected payload")
                    completion(nil)
                    return
                }
                
                guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                      let jwkSet = try? JSONDecoder().decode([JWKSet].self, from: data) else {
                          os_log("getPublicKey - JWS - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, "Unexpected payload")
                          completion(nil)
                          return
                      }
                
                // Save the keys to cache
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
                
            case .failure(let error):
                os_log("getGenericIssuer - JWS - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, error.localizedDescription)
                completion(nil)
            }
        }
    }
    
}

extension ResultViewController {
    
    private func getPublicKey(for cose: Cose, completion: @escaping (_ issuerKeys: [IssuerKey]?) -> Void) {
        
        guard let keyIdBytes = cose.keyId else {
            os_log("getPublicKey - Cose - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, "No KeyId")
            completion(nil)
            return
        }
        
        let keyId = keyIdBytes.base64EncodedString()
        
        //Look for cache
        if let cachedIssuerKeys = DataStore.shared.getIssuerKey(for: keyId), !(cachedIssuerKeys.isEmpty) {
            completion(cachedIssuerKeys)
            return
        }
        
        IssuerService().getGenericIssuer(issuerId: keyId, type: .DCC) { result in
            switch result {
            case .success(let json):
                guard let jsonPayload = json["payload"] as? [String : Any],
                      let payload = jsonPayload["payload"] as? [[String : Any]], !(payload.isEmpty) else {
                          os_log("getGenericIssuer - Cose - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, "Unexpected payload")
                          completion(nil)
                          return
                      }
                
                guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                      let issuerKeys = try? JSONDecoder().decode([IssuerKey].self, from: data) else {
                          os_log("getPublicKey - Cose - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, "Unexpected payload")
                          completion(nil)
                          return
                      }
                
                // Save the keys to cache
                DataStore.shared.addIssuerKeys(issuerKeys: issuerKeys)

                let requiredIssuerKeys = issuerKeys.filter({ $0.kid == keyId })
                
                guard !(requiredIssuerKeys.isEmpty) else {
                    os_log("getPublicKey - Cose - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, "No Issuer Keys found")
                    completion(nil)
                    return
                }
                
                completion(requiredIssuerKeys)
                
            case .failure(let error):
                os_log("getGenericIssuer - Cose - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, error.localizedDescription)
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

