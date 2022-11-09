//
//  VerifiableObject+SHC.swift
//  VerifiableCredential
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import OSLog

/**
 
 A collection of helper functions for validating and parsing SHC  Credential type
 
 */
extension VerifiableObject {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Methods
    
    internal func isValidSHC(message: String) -> Bool {
        guard message.hasPrefix(SHCPREFIX) else {
            return false
        }
        
        return true
    }
    
    internal func parse(shc: String) throws -> String? {
        let shcBody = String(shc.dropFirst(SHCPREFIX.count))
        
        guard shcBody.count % 2 == 0 else {
            os_log("SHC - body is invalid", log: OSLog.verifiableObjectOSLog, type: .error)
            return nil
        }
        
        let shcBodyArray = components(shc: shcBody, withLength: 2)
        let shcBodyIntArray = shcBodyArray.compactMap { Int($0.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) }
        
        let jwsBodyUnicodeScalarArray = shcBodyIntArray.compactMap { UnicodeScalar($0 + 45) }
        let jwsBodyStringArray = jwsBodyUnicodeScalarArray.map { String($0) }
        
        guard shcBodyArray.count == jwsBodyStringArray.count else {
            os_log("SHC - Data mismatch", log: OSLog.verifiableObjectOSLog, type: .error)
            return nil
        }
        
        let jws = jwsBodyStringArray.joined()
        
        return jws
    }
    
    internal func parse(jwsRepresentation: Data) throws -> String? {
        let jws = String(decoding: jwsRepresentation, as: UTF8.self)
        return jws
    }
    
    internal func shcRepresentation(for jwsRepresentation: Data) throws -> String? {
        guard let jws = try? parse(jwsRepresentation: jwsRepresentation) else {
            return nil
        }
        
        let jwsBodyUnicodeScalarArray = jws.unicodeScalars
        
        let shcBodyIntArray = jwsBodyUnicodeScalarArray.compactMap{ ($0.value - 45) }
        let shcBodyArray = shcBodyIntArray.compactMap{ String(format: "%02d", $0) }
        
        let shcBody = shcBodyArray.joined()
        let shc = String("\(SHCPREFIX)\(shcBody)")
        
        return shc
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Methods
    
    private func components(shc: String, withLength length: Int) -> [String] {
        return stride(from: 0, to: shc.count, by: length).map {
            let start = shc.index(shc.startIndex, offsetBy: $0)
            let end = shc.index(start, offsetBy: length, limitedBy: shc.endIndex) ?? shc.endIndex
            return String(shc[start..<end])
        }
    }
    
}
