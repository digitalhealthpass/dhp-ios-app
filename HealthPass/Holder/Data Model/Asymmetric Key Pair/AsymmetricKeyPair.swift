//
//  AsymmetricKeyPair.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit

struct AsymmetricKeyPair {
    var tag: String?
    var timestamp: String?

    var publickey: String?
    var privatekey: String?

    var rawDictionary: [String: Any]?
    var rawString: Any?

    init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        tag = value["tag"] as? String
        timestamp = value["timestamp"] as? String
        
        publickey = value["publickey"] as? String
        privatekey = value["privatekey"] as? String
    }
}

extension AsymmetricKeyPair {
    // Derived Data
    
    var timestampValue: Date {
        guard let timestamp = timestamp else {
            return Date()
        }
        
        return Date.dateFromString(dateString: timestamp, dateFormatPattern: .keyGenFormat)
    }

    var associatedContacts: [Contact] {
        let userContacts = DataStore.shared.userContacts
        let associatedContacts = userContacts.filter { $0.idCredential?.extendedCredentialSubject?.id == publickey }
        return associatedContacts
    }
    
    var canDelete: Bool {
        return associatedContacts.isEmpty
    }
    
}
