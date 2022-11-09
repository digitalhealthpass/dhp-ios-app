//
//  Labresult.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Labresult: Codable {
    enum CodingKeys: String, CodingKey {
        case type, issueDate, loinc, result
    }
    
    var type: String?
    var issueDate: String?
    var loinc: String?
    var result: String?
    
    /**
     A JSON represenstion of the Labresult object.
     */
    public var rawDictionary: [String: Any]?
    
    /**
     A String represenstion of the Labresult object.
     */
    public var rawString: String?
    
    init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        type = value["type"] as? String
        issueDate = value["issueDate"] as? String
        loinc = value["loinc"] as? String
        result = value["result"] as? String
    }
}
