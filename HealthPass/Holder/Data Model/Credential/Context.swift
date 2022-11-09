//
//  Context.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Context: Codable {
    enum CodingKeys: String, CodingKey {
        case cred
    }
    
    var cred: String?
    
    /**
     A JSON represenstion of the Context object.
     */
    public var rawDictionary: [String: Any]?
    
    /**
     A String represenstion of the Context object.
     */
    public var rawString: String?
    
    init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        cred = value["cred"] as? String
    }
}
