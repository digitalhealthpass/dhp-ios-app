//
//  CredentialPKIUtils.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import JOSESwift
import PromiseKit
import CryptoKit
import VerifiableCredential
import VerificationEngine

class CredentialPKIUtils {
    
    @discardableResult
    public func verifySignature(credential: Credential, publicKeys: [PublicKey]) -> Promise<String> {
        
        return Promise<String>(resolver: { resolver in
            
            //1. Get the signature from the credential for verification
            guard let signature = credential.proof?.signatureValue else {
                resolver.reject(NSError.credentialSignatureNoProperties)
                return
            }
            
            //2. Convert the signature string to data
            guard let rawSignature = Data(base64URLEncoded: signature) else {
                resolver.reject(NSError.credentialSignatureInvalidSignatureData)
                return
            }
            
            //3. Get the credential dictionary removing the signature value and any obfuscation
            //4. Convert the credential dictionary to data after sorting and without escaping slashes
            guard let unsignedCredentialDictionary = credential.unsignedCredentialDictionary,
                  let unsignedRawData = try? JSONSerialization.data(withJSONObject: unsignedCredentialDictionary, options: [.sortedKeys, .withoutEscapingSlashes]) else {
                resolver.reject(NSError.credentialSignatureInvalidCredentialData)
                return
            }
            
            //5. Convert the public key from issuer to JWK format
            let publicKeyJWKs = publicKeys.compactMap { $0.publicKeyJWK }
            
            //6. Convert the JWK format key to native SecKey format
            let nativePublicKeys = publicKeyJWKs.compactMap { convertJwkToSecKey(publicKeyJWK: $0) }
            
            //7. Check if the keys are capable for verification
            let canVerifyResults = nativePublicKeys.compactMap {
                SecKeyIsAlgorithmSupported($0, SecKeyOperationType.verify, SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256)
            }
            
            //8. Escape if the keys are not capable for verification
            guard canVerifyResults.contains(true) else {
                resolver.reject(NSError.credentialSignatureUnsupportedKey)
                return
            }
            
            //9. Check if the signatature matches the credential (actual signature verification)
            let results = nativePublicKeys.compactMap {
                SecKeyVerifySignature($0,
                                      SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256,
                                      unsignedRawData as CFData,
                                      rawSignature as CFData,
                                      nil)
            }
            
            //10. Check if verification was successful with any of the keys identified
            let status = results.contains(true)
            
            if status {
                resolver.fulfill("verification.validSignature".localized)
            } else {
                resolver.reject(NSError.credentialSignatureFailed)
            }
        })
        
    }
    
    @discardableResult
    public func verifySignature(jws: VerifiableCredential.JWS, signingKey: VerificationEngine.JWK) -> Promise<String>  {
        
        return Promise<String>(resolver: { resolver in
            
            guard let headerString = jws.headerString,
                  let payloadString = jws.payloadString,
                  let signatureString = jws.signatureString else {
                resolver.reject(NSError.credentialSignatureNoProperties)
                return
            }
            
            let headerAndPayloadString = headerString + "." + payloadString
            guard let message = headerAndPayloadString.data(using: .utf8) else {
                resolver.reject(NSError.credentialSignatureNoProperties)
                return
            }
            
            guard let signingPublicKey = try? signingKey.asP256PublicKey() else {
                resolver.reject(NSError.credentialSignatureNoProperties)
                return
            }
            
            guard let decodedSignature = try? VerificationEngine.Base64URL.decode(signatureString) else {
                resolver.reject(NSError.credentialSignatureNoProperties)
                return
            }
            
            guard let parsedECDSASignature = try? P256.Signing.ECDSASignature(rawRepresentation: decodedSignature) else {
                resolver.reject(NSError.credentialSignatureNoProperties)
                return
            }
            
            let result = signingPublicKey.isValidSignature(parsedECDSASignature, for: message)
            
            if result {
                resolver.fulfill("verification.validSignature".localized)
            } else {
                resolver.reject(NSError.credentialSignatureFailed)
            }

        })
    }
}

extension CredentialPKIUtils {
    
    private func convertJwkToSecKey(publicKeyJWK: VerificationEngine.JWK) -> SecKey? {
        guard let crvString = publicKeyJWK.crv, let crv = ECCurveType(rawValue: crvString),
              let x = publicKeyJWK.x, let y = publicKeyJWK.y else {
            return nil
        }
        
        let ecPublicKey = ECPublicKey(crv: crv, x: x, y: y)
        
        let secKey = try? ecPublicKey.converted(to: SecKey.self)
        return secKey
    }

}
