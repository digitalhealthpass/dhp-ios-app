//
//  Issuer.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Purpose: Codable {
    enum CodingKeys: String, CodingKey {
        case purpose, consentType, purposeCategory, piiCategory, termination, thirdPartyDisclosure
    }
    
    var purpose: String?
    var consentType: String?
    var purposeCategory: String?
    var piiCategory: [String]?
    var termination: String?
    var thirdPartyDisclosure: Bool?

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
        
        purpose = value["purpose"] as? String
        consentType = value["consentType"] as? String
        purposeCategory = value["purposeCategory"] as? String
        piiCategory = value["piiCategory"] as? [String]
        termination = value["termination"] as? String
        thirdPartyDisclosure = value["thirdPartyDisclosure"] as? Bool
    }
}

