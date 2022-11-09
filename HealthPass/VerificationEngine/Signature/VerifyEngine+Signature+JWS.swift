//
//  VerifyEngine+Signature+JWS.swift
//  VerificationEngine
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import VerifiableCredential
import CryptoKit
import OSLog

extension VerifyEngine {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Methods

    internal func hasValidSignature(for jws: JWS) throws -> Bool {
        //1. Get the jws basic properties
        guard let headerString = jws.headerString,
              let payloadString = jws.payloadString,
              let signatureString = jws.signatureString else {
            os_log("Signature - JWS - %{public}@", log: OSLog.VerifyEngineOSLog, type: .error, NSError.credentialSignatureNoProperties)
            throw NSError.credentialSignatureNoProperties
        }
        
        //2. Construct the data to verify using header and payload
        let headerAndPayloadString = headerString + "." + payloadString
        guard let message = headerAndPayloadString.data(using: .utf8) else {
            os_log("Signature - JWS - %{public}@", log: OSLog.VerifyEngineOSLog, type: .error, NSError.credentialSignatureInvalidCredentialData)
            throw NSError.credentialSignatureInvalidCredentialData
        }
        
        //3. Convert the JWK format key to native SecKey format
        guard let signingPublicKeys = jwkSet?.compactMap({ try? $0.asP256PublicKey() }) else {
            os_log("Signature - JWS - %{public}@", log: OSLog.VerifyEngineOSLog, type: .error, NSError.credentialSignatureNoKey)
            throw NSError.credentialSignatureNoKey
        }
        
        //4. Convert the signature string to data
        guard let decodedSignature = try? VerificationEngine.Base64URL.decode(signatureString) else {
            os_log("Signature - JWS - %{public}@", log: OSLog.VerifyEngineOSLog, type: .error, NSError.credentialSignatureInvalidSignatureData)
            throw NSError.credentialSignatureInvalidSignatureData
        }
        
        guard let parsedECDSASignature = try? P256.Signing.ECDSASignature(rawRepresentation: decodedSignature) else {
            os_log("Signature - JWS - %{public}@", log: OSLog.VerifyEngineOSLog, type: .error, NSError.credentialSignatureInvalidSignatureData)
            throw NSError.credentialSignatureInvalidSignatureData
        }
        
        //5. Check if the signatature matches the credential (actual signature verification)
        let results = signingPublicKeys.compactMap {  $0.isValidSignature(parsedECDSASignature, for: message) }
        
        //6. Check if verification was successful with any of the keys identified
        let status = results.contains(true)
        
        return status
    }
    
}

