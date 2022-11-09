//
//  CredentialVerifier.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import PromiseKit
import VerifiableCredential
import VerificationEngine

class CredentialVerifier {
    
    @discardableResult
    public func verifyCredential(credential: Credential) -> Promise<String>  {
        return Promise<String>(resolver: { resolver in
            self.checkSignature(for: credential)
                .done { _ in
                    resolver.fulfill("verification.successful".localized)
                }
                .catch { error in
                    resolver.reject(error)
                }
        })
    }
    
    @discardableResult
    public func checkSignature(for credential: Credential) -> Promise<String> {
        return Promise<String>(resolver: { resolver in
            guard let did = credential.issuer, let keyID = credential.proof?.creator else {
                resolver.reject(NSError.credentialSignatureNoProperties)
                return
            }
            
            IssuerUtils().getIssuerPublicKeys(for: did, and: keyID, completion: { publicKeys, errorMessage in
                guard let publicKeys = publicKeys else {
                    resolver.reject(NSError.credentialSignatureNoKey)
                    return
                }
                
                CredentialPKIUtils().verifySignature(credential: credential, publicKeys: publicKeys)
                    .done { result in
                        resolver.fulfill(result)
                    }.catch { error in
                        resolver.reject(error)
                    }
            })
        })
    }
    
}

extension CredentialVerifier {
    
    @discardableResult
    public func verifyJWS(jws: JWS) -> Promise<String>  {
        return Promise<String>(resolver: { resolver in
            self.checkSignature(for: jws)
                .done { _ in
                    resolver.fulfill("verification.successful".localized)
                }
                .catch { error in
                    resolver.reject(error)
                }
        })
    }
    
    @discardableResult
    public func checkSignature(for jws: JWS) -> Promise<String> {
        return Promise<String>(resolver: { resolver in
            
            guard let header = jws.header,
                  let payload = jws.payload, let issuerIdentifier = payload.iss else {
                resolver.reject(NSError.credentialSignatureNoProperties)
                return
            }
            
            // The standard URL to locate an issuer's signing public keys is constructed by appending `/.well-known/jwks.json` to the issuer's identifier.
            let issuerURLString = issuerIdentifier + "/.well-known/jwks.json"
            
            guard let issuerURL = URL(string: issuerURLString) else {
                resolver.reject(NSError.credentialSignatureNoProperties)
                return
            }
            
            IssuerUtils().getIssuerPublicKey(at: issuerURL) { publicKeys, errorMessage in
                guard let publicKeys = publicKeys else {
                    resolver.reject(NSError.credentialSignatureNoKey)
                    return
                }
                
                guard let signingKey = try? publicKeys.key(with: header.kid) else {
                    resolver.reject(NSError.credentialSignatureNoKey)
                    return
                }
                
                CredentialPKIUtils().verifySignature(jws: jws, signingKey: signingKey)
                    .done { result in
                        resolver.fulfill(result)
                    }.catch { error in
                        resolver.reject(error)
                    }
            }
        })
    }
}
