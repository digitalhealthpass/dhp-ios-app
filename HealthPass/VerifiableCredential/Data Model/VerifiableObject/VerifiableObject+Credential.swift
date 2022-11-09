//
//  VerifiableObject+Credential.swift
//  VerifiableCredential
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import OSLog

/**
 
 A collection of helper functions for Credential validation and getting info
 
 */
extension VerifiableObject {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Methods
    
    internal func getCredentialType(for credential: Credential?) -> VCType {
        guard let type = credential?.type else {
            return .unknown
        }
        
        if type.contains(VCType.IDHP.rawValue) {
            return .IDHP
        } else if type.contains(VCType.GHP.rawValue) {
            return .GHP
        } else if type.contains(VCType.DIVOC.rawValue) {
            return .DIVOC
        }
        
        return .VC
    }
    
    internal func isValidCredential(messages: String) -> Bool {
        guard let _ = self.jsonObject(from: messages) else {
            return false
        }
        
        return true
    }
    
    /// Constructs credential from the input message string
    internal func getCredential(messages: String) -> Credential? {
        let credential = Credential(value: messages)
        
        // Sanity check
        guard (credential.proof != nil), (credential.credentialSubject != nil),
              let type = credential.type, (type.contains("VerifiableCredential")) else {
            os_log("Credential - Proof, Type or Subject missing or Type invalid ", log: OSLog.verifiableObjectOSLog, type: .error)
            return nil
        }
        
        return credential
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Methods
    
    private func jsonObject(from stringValue: String) -> [String: Any]? {
        // 1st - try decoding from a string that contains the json data
        // 2nd - try decoding from a base 64 encoded string containing the json data
        if let jsonObject = try? JSONSerialization.jsonObject(with:Data(stringValue.utf8), options: []) as? [String: Any] {
            return jsonObject
        } else if let data = Data(base64Encoded: stringValue, options: .ignoreUnknownCharacters),
                  let jsonObject = try? JSONSerialization.jsonObject(with:data, options: []) as? [String: Any] {
            return jsonObject
        }
        
        return nil
    }
    
}

