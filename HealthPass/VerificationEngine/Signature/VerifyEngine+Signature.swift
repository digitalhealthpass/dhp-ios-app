//
//  VerifyEngine+Signature.swift
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
    // MARK: - Public
    // ======================================================================
    
    // MARK: Public Methods

    /// Verifies signature based on Verifiable Object's type
    ///
    public func hasValidSignature() throws -> Bool {
        guard let type = verifiableObject?.type else {
            os_log("- VerifyEngine - Signature - Unknown Type", log: OSLog.VerifyEngineOSLog, type: .info)
            return false
        }
        
        if let jws = verifiableObject?.jws {
            return try hasValidSignature(for: jws)
        } else if (type == .IDHP ||  type == .GHP || type == .VC), let credential = verifiableObject?.credential {
            return try hasValidIDHPSignature(for: credential)
        } else if let cose = verifiableObject?.cose {
            return try hasValidSignature(for: cose)
        }
        
        os_log("Signature - Unknown Object", log: OSLog.VerifyEngineOSLog, type: .info)
        return false
    }
    
}

/*
 private static let DEFAULT_TRUSTLIST_URL = "https://dgc.a-sit.at/ehn/cert/listv2"
 private static let DEFAULT_SIGNATURE_URL = "https://dgc.a-sit.at/ehn/cert/sigv2"
 private static let DEFAULT_TRUSTANCHOR = """
 MIIBJTCBy6ADAgECAgUAwvEVkzAKBggqhkjOPQQDAjAQMQ4wDAYDVQQDDAVFQy1N
 ZTAeFw0yMTA0MjMxMTI3NDhaFw0yMTA1MjMxMTI3NDhaMBAxDjAMBgNVBAMMBUVD
 LU1lMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE/OV5UfYrtE140ztF9jOgnux1
 oyNO8Bss4377E/kDhp9EzFZdsgaztfT+wvA29b7rSb2EsHJrr8aQdn3/1ynte6MS
 MBAwDgYDVR0PAQH/BAQDAgWgMAoGCCqGSM49BAMCA0kAMEYCIQC51XwstjIBH10S
 N701EnxWGK3gIgPaUgBN+ljZAs76zQIhAODq4TJ2qAPpFc1FIUOvvlycGJ6QVxNX
 EkhRcgdlVfUb
 """.replacingOccurrences(of: "\n", with: "")

 */
