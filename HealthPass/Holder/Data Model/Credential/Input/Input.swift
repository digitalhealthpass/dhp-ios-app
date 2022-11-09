//
//  Input.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Input: Codable {
    enum CodingKeys: String, CodingKey {
        case covid, exposure, temperature, healthcheck
    }
    
    var covid: String?
    var exposure: String?
    var temperature: String?
    var healthcheck: String?
    
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
        
        covid = value["covid"] as? String
        exposure = value["exposure"] as? String
        temperature = value["temperature"] as? String
        healthcheck = value["healthcheck"] as? String
    }
}

