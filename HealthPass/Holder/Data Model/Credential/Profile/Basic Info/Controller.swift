//
//  Controller.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Controller: Codable {
    enum CodingKeys: String, CodingKey {
        case contact, faq, name, privacyPolicy, userAgreement, website
    }
    
    var contact: String?
    var faq: String?
    var name: String?
    var privacyPolicy: String?
    var userAgreement: String?
    var website: String?

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
        
        contact = value["contact"] as? String
        faq = value["faq"] as? String
        name = value["name"] as? String
        privacyPolicy = value["privacyPolicy"] as? String
        userAgreement = value["userAgreement"] as? String
        website = value["website"] as? String
    }
}

