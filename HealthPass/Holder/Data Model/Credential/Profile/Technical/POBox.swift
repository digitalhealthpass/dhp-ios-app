//
//  Address.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct POBox: Codable {
    enum CodingKeys: String, CodingKey {
        case id, linkId, url, passcode, symmetricKey
    }
    
    var id: String?
    var linkId: String?
    var url: String?
    var passcode: String?
    var symmetricKey: POBoxSymmetricKey?
    
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
        
        id = value["id"] as? String
        linkId = value["linkId"] as? String
        url = value["url"] as? String
        passcode = value["passcode"] as? String
        
        if let symmetricKeyData = value["symmetricKey"] as? [String: Any] {
            symmetricKey = POBoxSymmetricKey(value: symmetricKeyData)
        }
    }
}

