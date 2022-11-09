//
//  PublicKey.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

public struct PublicKey: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id, type
        case controller
        case publicKeyJWK
    }
    
    public var id: String?
    var type: String?
    
    var controller: String?
    
    public var publicKeyJWK: JWK?
    
    /**
     A JSON represenstion of the Input object.
     */
    public var rawDictionary: [String: Any]?
    
    /**
     A String represenstion of the Input object.
     */
    public var rawString: String?
    
    public init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        id = value["id"] as? String
        type = value["type"] as? String
        
        controller = value["controller"] as? String
        
        if let publicKeyJWKData = value["publicKeyJwk"] as? [String: Any] {
            publicKeyJWK = JWK(value: publicKeyJWKData)
        }
    }
    
}


