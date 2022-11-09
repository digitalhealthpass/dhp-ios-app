//
//  VerifyEngine+Signature+Cose.swift
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

    func hasValidSignature(for cose: Cose) throws -> Bool {
        /* Only supporting Sign1 messages for the moment */
        switch cose.type {
        case .sign1:
            return hasCoseSign1ValidSignature(for: cose)
            
        default:
            os_log("Signature - COSE - Sign messages are not yet supported", log: OSLog.VerifyEngineOSLog, type: .error)
            return false
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods

    private func hasCoseSign1ValidSignature(for cose: Cose) -> Bool {
        guard let signedData = cose.signatureStruct else {
            os_log("Signature - COSE - Cannot create Sign1 structure", log: OSLog.VerifyEngineOSLog, type: .error)
            return false
        }
        
        return verifySignature(for: cose, signedData: signedData, rawSignature: cose.signature)
    }
    
    private func verifySignature(for cose: Cose, signedData: Data, rawSignature: Data) -> Bool {
        var algorithm : SecKeyAlgorithm
        var signature = rawSignature
        
        guard let keyStrings = issuerKeys?.compactMap({ $0.rawData }) else {
            os_log("Signature - COSE - No valid public key", log: OSLog.VerifyEngineOSLog, type: .error)
            return false
        }
        
        let keys = keyStrings.compactMap({ trustAnchorKey(for: $0) })
        
        guard (!keys.isEmpty) else {
            os_log("Signature - COSE - No valid public key", log: OSLog.VerifyEngineOSLog, type: .error)
            return false
        }

        switch cose.protectedHeader.algorithm {
        case .es256:
            algorithm = .ecdsaSignatureMessageX962SHA256
            signature = Asn1Encoder().convertRawSignatureIntoAsn1(rawSignature)
            
        case .ps256:
            algorithm = .rsaSignatureMessagePSSSHA256
            
        default:
            os_log("Signature - COSE - Verification algorithm not supported", log: OSLog.VerifyEngineOSLog, type: .error)
            return false
        }
        
        
        let results = keys.map ({
            SecKeyVerifySignature($0, algorithm, signedData as CFData, signature as CFData, nil)
        })
            
        let status = results.contains(true)

        return status
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
