//
//  Base64+Additions.swift
//  VerifiableCredential
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

/**
 
 A collection of helper functions for decoding from String to Data
 
 */

public struct Base64URL {
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: Public Methods

    public static func decode(_ value: String) throws -> Data {
        var base64 = value
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")
        
        // Properly pad the string.
        switch base64.count % 4 {
        case 0: break
        case 2: base64 += "=="
        case 3: base64 += "="
        default:
            throw Base64URLError.invalidBase64
        }
        
        guard let data = Data(base64Encoded: base64) else {
            throw Base64URLError.unableToCreateDataFromBase64String(base64)
        }
        
        return data
    }
    
}

public enum Base64URLError: Error {
    case invalidBase64
    case unableToCreateDataFromBase64String(String)
}

