//
//  Name.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Name: Codable {
    enum CodingKeys: String, CodingKey {
        case givenName, familyName
    }
    
    var givenName: String?
    var familyName: String?
    
    /**
     A JSON represenstion of the Name object.
     */
    public var rawDictionary: [String: Any]?
    
    /**
     A String represenstion of the Name object.
     */
    public var rawString: String?
    
    init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        givenName = value["givenName"] as? String ?? value["firstname"] as? String
        familyName = value["familyName"] as? String ?? value["lastname"] as? String
    }
}
