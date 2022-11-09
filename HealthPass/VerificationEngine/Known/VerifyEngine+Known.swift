//
//  VerifyEngine+Known.swift
//  VerificationEngine
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import OSLog

extension VerifyEngine {
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: Public Methods

    /// Checks whether the type  of VerifiableObject is known
    ///
    public func isKnown(_ supportedTypes: [String]? = nil) throws -> Bool {
        guard let type = verifiableObject?.type else {
            os_log("Known - Unknown Credential type", log: OSLog.VerifyEngineOSLog, type: .info)
            return false
        }
        
        if let supportedTypes = supportedTypes {
            return supportedTypes.contains(type.keyId)
        }
        
        return !(type == .unknown)
    }
    
}
