//
//  ObfuscatedField.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

public struct Obfuscation: Codable {
    enum CodingKeys: String, CodingKey {
        case val, alg, nonce, path
    }
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Properties
    
    public var val: String?
    public var alg: String?
    public var nonce: String?
    public var path: String?
    
}

extension Obfuscation {
    
    public init(value: [String: Any]) {
        val = value["val"] as? String
        alg = value["alg"] as? String
        nonce = value["nonce"] as? String
        path = value["path"] as? String
    }
    
    public func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    public func json() -> [String: Any]? {
        return try? JSONSerialization.jsonObject(with: try self.jsonData(), options: []) as? [String: Any]
    }
    
    public func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }

}
