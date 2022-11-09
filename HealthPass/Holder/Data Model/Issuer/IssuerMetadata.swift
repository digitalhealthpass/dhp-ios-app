//
//  IssuerMetadata.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct IssuerMetadata {
    var id: String?
    var name: String?

    var created_at: String?
    var updated_at: String?

    var metadata: [String: Any]?

    /**
     A JSON represenstion of the Input object.
     */
    public var rawDictionary: [String: Any]?
    
    /**
     A String represenstion of the Input object.
     */
    public var rawString: String?

    init(value: String) {
        rawString = value
        rawDictionary = (try? JSONSerialization.jsonObject(with:Data(value.utf8), options: []) as? [String : Any]) ?? [String : Any]()

        id = rawDictionary?["id"] as? String
       
        if let metadata = rawDictionary?["metadata"] as? [String: Any] {
            name = metadata["name"] as? String
        }

        created_at = rawDictionary?["created_at"] as? String
        updated_at = rawDictionary?["updated_at"] as? String

        metadata = rawDictionary?["metadata"] as? [String: Any] ?? [String: Any]()
    }
    
    init(value: [String: Any]) {
        let value = value.mapValues { $0 is NSNull ? nil : $0 }
        rawDictionary = value.compactMapValues { $0 }
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }

        id = rawDictionary?["id"] as? String
        
        if let metadata = rawDictionary?["metadata"] as? [String: Any] {
            name = metadata["name"] as? String
        }

        created_at = rawDictionary?["created_at"] as? String
        updated_at = rawDictionary?["updated_at"] as? String

        metadata = rawDictionary?["metadata"] as? [String: Any] ?? [String: Any]()
    }
    
}
