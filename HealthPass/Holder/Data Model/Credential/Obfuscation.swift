//
//  ObfuscatedField.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Obfuscation: Codable {
    enum CodingKeys: String, CodingKey {
        case val, alg, nonce, path
    }
    
    var val: String?
    var alg: String?
    var nonce: String?
    var path: String?
    
    /**
     A JSON represenstion of the Proof object.
     */
    public var rawDictionary: [String: Any]?
    
    /**
     A String represenstion of the Proof object.
     */
    public var rawString: String?
    
    init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        val = value["val"] as? String
        alg = value["alg"] as? String
        nonce = value["nonce"] as? String
        path = value["path"] as? String
    }
}
