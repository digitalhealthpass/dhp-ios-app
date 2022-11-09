//
//  Schema.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit

struct Schema {
    
    var type: String?
    var modelVersion: String?
    var id: String?

    var name: String?
    var author: String?
    var authored: String?
    
    var schema: [String: Any]?
    
    //var proof: Proof?
    
    var authorName: String?
    var schemaUrlString: String?

    var rawDictionary: [String: Any]?
    var rawString: String? 
    
    init(value: String) {
        rawString = value
        rawDictionary = (try? JSONSerialization.jsonObject(with:Data(value.utf8), options: []) as? [String : Any]) ?? [String : Any]()
                
        type = rawDictionary?["@type"] as? String
        modelVersion = rawDictionary?["modelVersion"] as? String
        id = rawDictionary?["id"] as? String
        
        name = rawDictionary?["name"] as? String
        author = rawDictionary?["author"] as? String
        authored = rawDictionary?["authored"] as? String

        schema = rawDictionary?["schema"] as? [String: Any]

//        if let proofData = rawDictionary?["proof"] as? [String: Any] {
//            proof = Proof(value: proofData)
//        }
        
        authorName = rawDictionary?["authorName"] as? String
        schemaUrlString = rawDictionary?["schemaURLString"] as? String
    }
    
    init(value: [String: Any]) {
        let value = value.mapValues { $0 is NSNull ? nil : $0 }
        rawDictionary = value.compactMapValues { $0 }
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        type = rawDictionary?["@type"] as? String
        modelVersion = rawDictionary?["modelVersion"] as? String
        id = rawDictionary?["id"] as? String
        
        name = rawDictionary?["name"] as? String
        author = rawDictionary?["author"] as? String
        authored = rawDictionary?["authored"] as? String

        schema = rawDictionary?["schema"] as? [String: Any]

//        if let proofData = rawDictionary?["proof"] as? [String: Any] {
//            proof = Proof(value: proofData)
//        }
        
        authorName = rawDictionary?["authorName"] as? String
        schemaUrlString = rawDictionary?["schemaURLString"] as? String
    }
    
    ///Derived Data
    var schemaUrl: URL? {
//        guard let schemaUrlString = String("https://en.wikipedia.org/wiki/Acme") else {
//            return nil
//        }
        
        let schemaUrlString = String("https://en.wikipedia.org/wiki/Acme")
        return URL(string: schemaUrlString)
    }
}

