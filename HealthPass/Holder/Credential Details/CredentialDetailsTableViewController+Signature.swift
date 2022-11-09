//
//  CredentialDetailsTableViewController+Signature.swift
//  Holder
//
//  Created by Yevtushenko Valeriia on 25.01.2022.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import PromiseKit
import VerifiableCredential
import VerificationEngine

extension CredentialDetailsTableViewController {
    
    internal func isValidSignature() -> Promise<Void> {
        return Promise { resolver in
            guard let package = self.package else {
                resolver.reject(NSError.credentialSignatureNoProperties)
                return
            }
            
            if package.type == .IDHP || package.type == .GHP || package.type == .VC, let credential = package.credential {
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
            } else if package.type == .SHC, let jws = package.jws {
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
            } else if package.type == .DCC, let cose = package.cose {
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
    
}

extension CredentialDetailsTableViewController {
    
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
                
            case .failure(_):
                completion(nil)
            }
        }
    }
    
}

extension CredentialDetailsTableViewController {
    
    private func getPublicKey(for jws: JWS, completion: @escaping (_ jwkKeys: [JWK]?) -> Void) {
        guard let issuerIdentifier = jws.payload?.iss else {
            completion(nil)
            return
        }
        
        //1. Check if the details can be found in cache
        if let cachedJWKSet = DataStore.shared.getJWKSet(for: issuerIdentifier) {
            let jwkKeys = cachedJWKSet.flatMap({ $0.keys })
            completion(jwkKeys)
            return
        }
        
        //2. Invoke the API to get issuer details
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
                
                //3. Save the keys to cache
                DataStore.shared.addJWKSet(jwkSet: jwkSet)
                
                let filteredJwkSet = jwkSet.compactMap ({ return ($0.url == issuerIdentifier) ? $0 : nil })
                
                let jwkKeys = filteredJwkSet.flatMap({ $0.keys })
                guard !(jwkKeys.isEmpty) else {
                    completion(nil)
                    return
                }
                
                completion(jwkKeys)
                
            case .failure(_):
                completion(nil)
            }
        }
    }
    
}

extension CredentialDetailsTableViewController {
    
    private func getPublicKey(for cose: Cose, completion: @escaping (_ issuerKeys: [IssuerKey]?) -> Void) {
        
        guard let keyIdBytes = cose.keyId else {
            completion(nil)
            return
        }
        
        let keyId = keyIdBytes.base64EncodedString()
        
        //1. Check if the details can be found in cache
        if let cachedIssuerKeys = DataStore.shared.getIssuerKey(for: keyId), !(cachedIssuerKeys.isEmpty) {
            completion(cachedIssuerKeys)
            return
        }
        
        //2. Invoke the API to get issuer details
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
                
                //3. Save the keys to cache
                DataStore.shared.addIssuerKeys(issuerKeys: issuerKeys)
                
                let requiredIssuerKeys = issuerKeys.filter({ $0.kid == keyId })
                
                guard !(requiredIssuerKeys.isEmpty) else {
                    completion(nil)
                    return
                }
                
                completion(requiredIssuerKeys)
                
            case .failure(_):
                completion(nil)
            }
        }
        
    }
    
}


