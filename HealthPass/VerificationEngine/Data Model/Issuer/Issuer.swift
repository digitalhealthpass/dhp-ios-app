//
//  Issuer.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

public struct Issuer: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name
        case created, updated
        case publicKey
    }
    
    public var id: String?
    public var name: String?
    
    var created: String?
    var updated: String?
    
    public var publicKey: [PublicKey]?
    
    /**
     A JSON representation of the Input object.
     */
    public var rawDictionary: [String: Any]?
    
    /**
     A String representation of the Input object.
     */
    public var rawString: String?
    
    public init(value: [String: Any]) {
        let value = value.mapValues { $0 is NSNull ? nil : $0 }
        rawDictionary = value.compactMapValues { $0 }
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        id = value["id"] as? String
        name = value["name"] as? String
        
        created = value["created"] as? String
        updated = value["updated"] as? String
        
        if let publicKeyData = value["publicKey"] as? [[String: Any]] {
            publicKey = publicKeyData.compactMap { PublicKey(value: $0) }
        }
    }
}


