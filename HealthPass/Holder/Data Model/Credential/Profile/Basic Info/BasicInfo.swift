//
//  BasicInfo.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct BasicInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case controller
        case services
    }
    
    var controller: Controller?
    
    var services: [Services]?
    
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
        
        if let controllerFields = value["controller"] as? [String: Any] {
            controller = Controller(value: controllerFields)
        }
        
        if let servicesFields = value["services"] as? [[String: Any]] {
            services = servicesFields.compactMap { Services(value: $0) }
        }
    }
}

