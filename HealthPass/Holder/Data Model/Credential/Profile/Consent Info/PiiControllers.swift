//
//  PiiControllers.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct PiiControllers: Codable {
    enum CodingKeys: String, CodingKey {
        case piiController, onbehalf, contact
        case address
        case email, phone, piiControllerUrl
    }
    
    var piiController: String?
    var onbehalf: Bool?
    var contact: String?
   
    var address: Address?
    
    var email: String?
    var phone: String?
    var piiControllerUrl: String?

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
        
        piiController = value["piiController"] as? String
        onbehalf = value["onbehalf"] as? Bool
        contact = value["contact"] as? String
        
        if let addressData = value["address"] as? [String: Any] {
            address = Address(value: addressData)
        }
        
        email = value["email"] as? String
        phone = value["phone"] as? String
        piiControllerUrl = value["piiControllerUrl"] as? String
    }
}

