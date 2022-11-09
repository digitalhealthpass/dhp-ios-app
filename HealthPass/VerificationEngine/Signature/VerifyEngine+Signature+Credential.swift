//
//  VerifyEngine+Signature+Credential.swift
//  VerificationEngine
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import VerifiableCredential
import JOSESwift
import CryptoKit
import OSLog

extension VerifyEngine {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Methods
    
    internal func hasValidIDHPSignature(for credential: Credential) throws -> Bool {
        
        //1. Get the signature from the credential for verification
        guard let signature = credential.proof?.signatureValue else {
            os_log("Signature - Credential - %{public}@", log: OSLog.VerifyEngineOSLog, type: .error, NSError.credentialSignatureNoProperties)
            throw NSError.credentialSignatureNoProperties
        }
        
        //2. Convert the signature string to data
        guard let decodedSignature = try? Base64URL.decode(signature) else {
            os_log("Signature - Credential - %{public}@", log: OSLog.VerifyEngineOSLog, type: .error, NSError.credentialSignatureInvalidSignatureData)
            throw NSError.credentialSignatureInvalidSignatureData
        }
        
        //3. Get the credential dictionary removing the signature value and any obfuscation
        
        guard var signedCredentialDictionary = credential.rawDictionary else {
            os_log("Signature - Credential - %{public}@", log: OSLog.VerifyEngineOSLog, type: .error, NSError.credentialSignatureInvalidCredentialData)
            throw NSError.credentialSignatureInvalidCredentialData
        }
        
        // 3.a. Remove signatureValue for verification process
        if var proof = signedCredentialDictionary["proof"] as? [String: Any] {
            proof["signatureValue"] = nil
            signedCredentialDictionary["proof"] = proof
        }
        
        //3.b. Remove obfuscation for verification process
        signedCredentialDictionary["obfuscation"] = nil
        
        //4.a. Convert the credential dictionary to data after sorting and without escaping slashes
        guard let signedCredentialDictionaryRawData = try? JSONSerialization.data(withJSONObject: signedCredentialDictionary, options: [.sortedKeys, .withoutEscapingSlashes]) else {
            os_log("Signature - Credential - %{public}@", log: OSLog.VerifyEngineOSLog, type: .error, NSError.credentialSignatureInvalidCredentialData)
            throw NSError.credentialSignatureInvalidCredentialData
        }
        
        //4.b. Convert the credential string to data after sorting
        let signedCredentialNSDictionary = NSDictionary(dictionary: signedCredentialDictionary)
        let signedCredentialString = self.canonicalJSONRepresentation(dictionary: signedCredentialNSDictionary)
        let signedCredentialStringRawData = Data(signedCredentialString.utf8)
        
        guard let keyID = credential.proof?.creator,
              let publicKeys = issuer?.publicKey?.filter({ $0.id == keyID }) else {
                  os_log("Signature - Credential - %{public}@", log: OSLog.VerifyEngineOSLog, type: .error, NSError.credentialSignatureUnavailableKey)
                  throw NSError.credentialSignatureUnavailableKey
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
            throw NSError.credentialSignatureUnsupportedKey
        }
        
        //9.a. Check if the signature matches the credential dictionary data (actual signature verification)
        let dictionaryResults = nativePublicKeys.compactMap {
            SecKeyVerifySignature($0,
                                  SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256,
                                  signedCredentialDictionaryRawData as CFData,
                                  decodedSignature as CFData,
                                  nil)
        }
        
        //9.b. Check if the signature matches the credential string data (actual signature verification)
        let stringResults = nativePublicKeys.compactMap {
            SecKeyVerifySignature($0,
                                  SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256,
                                  signedCredentialStringRawData as CFData,
                                  decodedSignature as CFData,
                                  nil)
        }
        
        //10. Check if verification was successful with any of the keys identified
        let status = dictionaryResults.contains(true) || stringResults.contains(true)
        
        if status {
            return true
        }
        
        throw NSError.credentialSignatureFailed
    }
    
    /*
     catch {
     os_log("Signature - Credential - %{public}@", log: OSLog.VerifyEngineOSLog, type: .error, error.localizedDescription)
     throw error
     }
     */
    
}

extension VerifyEngine {
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods
    
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

extension VerifyEngine {
    
    /// Utility method which converts a dictionary object to its JSON string format
    ///
    private func canonicalJSONRepresentation(dictionary: NSDictionary) -> String {
        var jsonString = "{"
        
        guard let allKeys = dictionary.allKeys as? [String] else {
            jsonString.append("}")
            return jsonString
        }
        
        let keys = allKeys.sorted(by: { $0.compare($1) == .orderedAscending })
        
        keys.forEach { key in
            jsonString.append("\"\(key)\":")
            
            if let valueDictionary = dictionary[key] as? NSDictionary {
                jsonString.append(canonicalJSONRepresentation(dictionary: valueDictionary))
            } else if let valueArray = dictionary[key] as? NSArray {
                jsonString.append(canonicalJSONRepresentation(array: valueArray))
            } else if let valueObject = dictionary[key] {
                jsonString.append(canonicalJSONRepresentation(object: valueObject))
            }
            
            jsonString.append(",")
        }
        
        jsonString = String(jsonString.dropLast())
        jsonString.append("}")
        return jsonString
    }
    
    /// Utility method which converts a array object to its JSON string format
    ///
    private func canonicalJSONRepresentation(array: NSArray) -> String {
        var jsonString = "["
        
        array.forEach { item in
            if let valueDictionary = item as? NSDictionary {
                jsonString.append(canonicalJSONRepresentation(dictionary: valueDictionary))
            } else if let valueArray = item as? NSArray {
                jsonString.append(canonicalJSONRepresentation(array: valueArray))
            } else {
                jsonString.append(canonicalJSONRepresentation(object: item))
            }
            
            jsonString.append(",")
        }
        
        jsonString = String(jsonString.dropLast())
        jsonString.append("]")
        return jsonString
    }
    
    /// Utility method which converts a generic object to its JSON string format
    ///
    private func canonicalJSONRepresentation(object: Any) -> String {
        if let valueString = object as? String {
            return String("\"\(valueString)\"")
        }
        
        return String(describing: object)
    }
    
}
