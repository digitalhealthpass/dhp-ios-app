//
//  Issuer.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct ConsentInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case version, jurisdiction, language, piiPrincipalId
        case piiControllers
        case policyUrl
        case services
        case sensitive
        case spiCat
    }
    
    var version: String?
    var jurisdiction: String?
    var language: String?
    var piiPrincipalId: String?

    var piiControllers: [PiiControllers]?
    
    var policyUrl: String?

    var services: [Services]?
    
    var sensitive: Bool?
    
    var spiCat: [String]?

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
        
        version = value["version"] as? String
        jurisdiction = value["jurisdiction"] as? String
        language = value["language"] as? String
        piiPrincipalId = value["piiPrincipalId"] as? String
        
        if let piiControllerFields = value["piiControllers"] as? [[String: Any]] {
            piiControllers = piiControllerFields.compactMap { PiiControllers(value: $0) }
        }
        
        policyUrl = value["policyUrl"] as? String

        if let servicesFields = value["services"] as? [[String: Any]] {
            services = servicesFields.compactMap { Services(value: $0) }
        }
        
        sensitive = value["sensitive"] as? Bool

        spiCat = value["spiCat"] as? [String]
    }
}

