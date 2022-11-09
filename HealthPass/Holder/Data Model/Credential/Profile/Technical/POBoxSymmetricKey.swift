//
//  POBoxSymmetricKey.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct POBoxSymmetricKey: Codable {
    enum CodingKeys: String, CodingKey {
        case algorithm, iv, value
    }
    
    var algorithm: String?
    var iv: String?
    var value: String?
    
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
        
        algorithm = value["algorithm"] as? String
        iv = value["iv"] as? String
        self.value = value["value"] as? String
    }
}

