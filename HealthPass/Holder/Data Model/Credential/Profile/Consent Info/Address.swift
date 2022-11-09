//
//  Address.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Address: Codable {
    enum CodingKeys: String, CodingKey {
        case line, city, state, postalCode, country
    }
    
    var line: String?
    var city: String?
    var state: String?
    var postalCode: String?
    var country: String?
    
    /**
     A JSON represenstion of the Input object.
     */
    public var rawDictionary: [String: Any]?
    
    /**
     A String represenstion of the Input object.
     */
    public var rawString: String?
    
    init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        line = value["line"] as? String
        city = value["city"] as? String
        state = value["state"] as? String
        postalCode = value["postalCode"] as? String
        country = value["country"] as? String
    }
}

