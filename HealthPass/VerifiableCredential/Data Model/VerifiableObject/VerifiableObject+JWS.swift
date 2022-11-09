//
//  VerifiableObject+JWS.swift
//  VerifiableCredential
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import OSLog

/**
 
 A collection of helper functions for validating and parsing JWS 
 
 */
extension VerifiableObject {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Methods
    
    internal func isValidJWS(message: String) -> Bool {
        let segments = message.components(separatedBy: ".")
        return (segments.count == 3)
    }
    
    internal func getJWS(for messages: String) -> JWS? {
        let jws = JWS(value: messages)
        
        // Sanity check
        guard (jws.headerString != nil), (jws.payloadString != nil), (jws.signatureString != nil) else {
            os_log("JWS - Header, Payload or Signature missing", log: OSLog.verifiableObjectOSLog, type: .error)
            return nil
        }
        
        return jws
    }
    
}
