//
//  VerifiableObject+HC1.swift
//  VerifiableCredential
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Gzip
import OSLog

/**
 
 A collection of helper functions for validating and parsing HC1 Credential type
 
 */
extension VerifiableObject {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Methods
    
    internal func isValidHC1(message: String) -> Bool {
        guard message.hasPrefix(HC1PREFIX) else {
            return false
        }
        
        return true
    }
    
    internal func parse(hc1: String) throws -> Cose? {
        let hc1Body = String(hc1.dropFirst(HC1PREFIX.count))
        
        guard let decodedData = decode(hc1Body) else {
            return nil
        }
        
        guard let decompressedData = decompress(decodedData) else {
            os_log("HC1 - Decompression failed", log: OSLog.verifiableObjectOSLog, type: .error)
            return nil
        }

        guard let cose = cose(from: decompressedData) else {
            os_log("HC1 - COSE Deserialization failed", log: OSLog.verifiableObjectOSLog, type: .error)
            return nil
        }
        
        return cose
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Methods
    
    /// Base45-decodes an EHN health certificate
    private func decode(_ encodedData: String) -> Data? {
        return try? encodedData.fromBase45()
    }
    
    /// Decompress the EHN health certificate using ZLib
    private func decompress(_ encodedData: Data) -> Data? {
        return try? encodedData.gunzipped()
    }

    /// Creates COSE structure from EHN health certificate
    private func cose(from data: Data) -> Cose? {
       return Cose(from: data)
    }
    
}

