//
//  CBOR+Extensions.swift
//  VerifiableCredential
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import SwiftCBOR

/**
 
 A collection of helper functions to cast from CBOR object types to Swift primitive types
 
 */
extension CBOR {
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Methods
    
    public func unwrap() -> Any? {
        switch self {
        case .simple(let value): return value
        case .boolean(let value): return value
        case .byteString(let value): return value
        case .date(let value): return value
        case .double(let value): return value
        case .float(let value): return value
        case .half(let value): return value
        case .tagged(let tag, let cbor): return (tag, cbor)
        case .array(let array): return array
        case .map(let map): return map
        case .utf8String(let value): return value
        case .negativeInt(let value): return value
        case .unsignedInt(let value): return value
        default:
            return nil
        }
    }
    
    public func asUInt64() -> UInt64? {
        return self.unwrap() as? UInt64
    }
    
    public func asDouble() -> Double? {
        return self.unwrap() as? Double
    }
    
    public func asInt64() -> Int64? {
        return self.unwrap() as? Int64
    }
    
    public func asString() -> String? {
        return self.unwrap() as? String
    }
    
    public func asList() -> [CBOR]? {
        return self.unwrap() as? [CBOR]
    }
    
    public func asMap() -> [CBOR:CBOR]? {
        return self.unwrap() as? [CBOR:CBOR]
    }
    
    public func asBytes() -> [UInt8]? {
        return self.unwrap() as? [UInt8]
    }
    
    public func asData() -> Data {
        return Data(self.encode())
    }
     
    public func asCose() -> (CBOR.Tag, [CBOR])? {
        guard let rawCose =  self.unwrap() as? (CBOR.Tag, CBOR),
              let cosePayload = rawCose.1.asList() else {
            return nil
        }
        return (rawCose.0, cosePayload)
    }
    
    public func decodeBytestring() -> CBOR? {
        guard let bytestring = self.asBytes(),
              let decoded = try? CBORDecoder(input: bytestring).decodeItem() else {
            return nil
        }
        return decoded
    }
}

/// Methods to cast collections of CBOR types in the form of the dictionary/list
extension CBOR {
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Properties
    
    public static func decodeList(_ list: [CBOR]) -> [Any] {
        var result = [Any]()
        
        for val in list {
            let unwrappedValue = val.unwrap()
            if let unwrappedValue = unwrappedValue as? [CBOR:CBOR] {
                result.append(decodeDictionary(unwrappedValue))
            } else if let unwrappedValue = unwrappedValue as? [CBOR] {
                result.append(decodeList(unwrappedValue))
            } else if let unwrappedValue = unwrappedValue {
                result.append(unwrappedValue)
            }
        }
        return result
    }
    
    public static func decodeDictionary(_ dictionary: [CBOR:CBOR]) -> [String: Any] {
        var payload = [String: Any]()
        
        for (key, val) in dictionary {
            if let key = key.asString() {
                let unwrappedValue = val.unwrap()
                if let unwrappedValue = unwrappedValue as? [CBOR:CBOR] {
                    payload[key] = decodeDictionary(unwrappedValue)
                } else if let unwrappedValue = unwrappedValue as? [CBOR] {
                    payload[key] = decodeList(unwrappedValue)
                } else if let unwrappedValue = unwrappedValue {
                    payload[key] = unwrappedValue
                }
            }
        }
        return payload
    }
}

/// COSE Message Identification
extension CBOR.Tag {
    /// Tagged COSE Sign1 Structure
    public static let coseSign1Item = CBOR.Tag(rawValue: 18)
    /// Tagged COSE Sign Structure
    public static let coseSignItem = CBOR.Tag(rawValue: 98)
}

// MARK: - Dictionary subscript extensions

extension Dictionary where Key == CBOR {
    subscript<Index: RawRepresentable>(index: Index) -> Value? where Index.RawValue == String {
        return self[CBOR(stringLiteral: index.rawValue)]
    }
    
    subscript<Index: RawRepresentable>(index: Index) -> Value? where Index.RawValue == Int {
        return self[CBOR(integerLiteral: index.rawValue)]
    }
}

// MARK: - CBOR Type

enum CborType: UInt8 {
    case tag = 210
    case list = 132
    case cwt = 216
    case unknown
    
    static func from(data: Data) -> CborType {
        switch data.bytes[0] {
        case self.tag.rawValue: return tag
        case list.rawValue: return list
        case cwt.rawValue: return cwt
        default: return unknown
        }
    }
}

// MARK: - Trimming Data methods extension

extension Data {
    func humanReadable() -> String {
        return self.map { String(format: "%02x ", $0) }.joined()
    }
    
    public var bytes : [UInt8] {
        return [UInt8](self)
    }
    
    func base64UrlEncodedString() -> String {
        return self.base64EncodedString(options: .endLineWithLineFeed)
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }
}

// MARK: - Double extension

extension Double {
    func toUInt64() -> UInt64 {
        return UInt64(self)
    }
}
