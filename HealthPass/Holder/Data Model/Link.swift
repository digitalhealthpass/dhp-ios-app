//
//  Link.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Link {
    var created_at: String?
    var expires_at: String?
    
    var id: String?
    var password: String?
    
    var multiple: String?

    var rawDictionary: [String: Any]?
    var rawString: String?
    
    init(value: String) {
        rawString = value
        rawDictionary = (try? JSONSerialization.jsonObject(with:Data(value.utf8), options: []) as? [String : Any]) ?? [String : Any]()
        
        created_at = rawDictionary?["created_at"] as? String
        expires_at = rawDictionary?["expires_at"] as? String
        
        id = rawDictionary?["id"] as? String
        password = rawDictionary?["password"] as? String

        multiple = rawDictionary?["multiple"] as? String
    }
    
    init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        created_at = rawDictionary?["created_at"] as? String
        expires_at = rawDictionary?["expires_at"] as? String
        
        id = rawDictionary?["id"] as? String
        password = rawDictionary?["password"] as? String

        multiple = rawDictionary?["multiple"] as? String
    }
}
