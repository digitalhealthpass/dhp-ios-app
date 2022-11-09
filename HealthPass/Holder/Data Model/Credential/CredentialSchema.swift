//
//  CredentialSchema.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct CredentialSchema: Codable {
    enum CodingKeys: String, CodingKey {
        case type, id
    }
    
    /**
     id property that MUST be a URI identifying the schema file
     */
    public var id: String?
    /**
     type (for example, JsonSchemaValidator2018)
     */
    public var type: String?
    
    /**
     A JSON represenstion of the CredentialSchema object.
     */
    public var rawDictionary: [String: Any]?
    
    /**
     A String represenstion of the CredentialSchema object.
     */
    public var rawString: String?
    
    init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        id = value["id"] as? String
        type = value["type"] as? String
    }
}
