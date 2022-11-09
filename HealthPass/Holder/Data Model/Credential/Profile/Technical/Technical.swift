//
//  Issuer.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Technical: Codable {
    enum CodingKeys: String, CodingKey {
        case poBox, download, upload, termination
    }
    
    var download: POBox?
    var upload: POBox?
    var symmetricKey: POBoxSymmetricKey?
    
    var poBox: POBox?
    var termination: Termination?

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
        
        //UPLOAD & DOWNLOAD section
        if let downloadData = value["download"] as? [String: Any] {
            download = POBox(value: downloadData)
        }
        
        if let uploadData = value["upload"] as? [String: Any] {
            upload = POBox(value: uploadData)
        }

        if let symmetricKeyData = value["symmetricKey"] as? [String: Any] {
            symmetricKey = POBoxSymmetricKey(value: symmetricKeyData)
        }

        //POBOX section
        if let poBoxData = value["poBox"] as? [String: Any] {
            poBox = POBox(value: poBoxData)
        }

        if let terminationData = value["termination"] as? [String: Any] {
            termination = Termination(value: terminationData)
        }
    }
}

