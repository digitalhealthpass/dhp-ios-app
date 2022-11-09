//
//  Person.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Person: Codable {
    enum CodingKeys: String, CodingKey {
        case mrn, identifier, name
    }
    
    var mrn: String?
    var identifier: String?
    
    var name: Name?
    
    /**
     A JSON represenstion of the Person object.
     */
    public var rawDictionary: [String: Any]?
    
    /**
     A String represenstion of the Person object.
     */
    public var rawString: String?
    
    init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        mrn = value["mrn"] as? String
        identifier = value["identifier"] as? String
        
        if let nameData = value["name"] as? [String: Any] {
            name = Name(value: nameData)
        }
    }
}
