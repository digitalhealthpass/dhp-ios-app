//
//  Proof.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Proof: Codable {
    enum CodingKeys: String, CodingKey {
        case created, creator, nonce, signatureValue, type
    }
    
    var created: String?
    var creator: String?
    var nonce: String?
    var signatureValue: String?
    var type: String?
    
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
        
        created = value["created"] as? String
        creator = value["creator"] as? String
        nonce = value["nonce"] as? String
        signatureValue = value["signatureValue"] as? String
        type = value["type"] as? String
    }
}
