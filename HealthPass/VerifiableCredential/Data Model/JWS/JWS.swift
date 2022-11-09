//
//  JWS.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Compression

/// Enum representing errors which could occur during JWS Parsing.
public enum JWSError: Error {
    
    // A JWS should have 3 segments: header, payload, and signature.
    case invalidNumberOfSegments(Int)
}

public struct JWS: Codable {
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Properties
    
    public var jws: String?
    
    // Segments
    public let headerString: String?
    public let payloadString: String?
    public let signatureString: String?
    
    // MARK: - Initializer
    
    public init(value: String) {
        jws = value
        
        let split = JWS.split(compactSerialization: value)
        
        headerString = split?.0
        payloadString = split?.1
        signatureString = split?.2
    }

}

extension JWS {
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Properties
    
    public var header: JWSHeader? {
        guard let headerString = headerString else { return nil }
        guard let headerData = try? Base64URL.decode(headerString) else { return nil }
        
        let parsedHeader = try? JSONDecoder().decode(JWSHeader.self, from: headerData)
        
        return parsedHeader
    }
    
    public var payloadData: Data? {
        guard let payloadString = payloadString else { return nil }
        guard var payloadData = try? Base64URL.decode(payloadString) else { return nil }
        
        if header?.zip == .deflate,
           let decompressedPayload = try? payloadData.decompress() {
            payloadData = decompressedPayload
        }
        
        return payloadData
    }
    
    public var payload: JWSPayload? {
        guard let payloadData = payloadData else { return nil }
       
        guard let payloadJSON = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String : Any] else { return nil }
        
        let parsedPayload = JWSPayload(from: payloadJSON)
        return parsedPayload
    }

    public var signature: String? {
        guard let signatureString = signatureString else { return nil }
        return signatureString
    }
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Methods
    
    private static func split(compactSerialization: String) -> (String, String, String)? {
        let parts = compactSerialization.split(separator: ".").map { String($0) }
        guard parts.count == 3 else {
            return nil
        }
        
        return (parts[0], parts[1], parts[2])
    }
    
}

extension Data {
    
    func decompress() throws -> Data {
        var decompressed = Data()
        let outputFilter = try OutputFilter(.decompress, using: .zlib) { (data: Data?) in
            if let data = data {
                decompressed.append(data)
            }
        }
        
        let pageSize = 512
        var index = 0
        
        // Feed data to the OutputFilter until there is none left to decompress.
        while true {
            let rangeLength = Swift.min(pageSize, count - index)
            let subrange = subdata(in: index ..< index + rangeLength)
            index += rangeLength
            
            try outputFilter.write(subrange)
            if rangeLength == 0 {
                break
            }
        }
        return decompressed
    }
    
}

public struct Base64URL {
    
    ///  Helper function to decode from Base64 String to Data.
    public static func decode(_ value: String) throws -> Data {
        var base64 = value
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")
        
        // Properly pad the string.
        switch base64.count % 4 {
        case 0: break
        case 2: base64 += "=="
        case 3: base64 += "="
        default: throw Base64URLError.invalidBase64
        }
        
        guard let data = Data(base64Encoded: base64) else {
            throw Base64URLError.unableToCreateDataFromBase64String(base64)
        }
        return data
    }
    
}

/// Enum representing possible errors during Base64 String decoding. 
public enum Base64URLError: Error {
    case invalidBase64
    case unableToCreateDataFromBase64String(String)
}
