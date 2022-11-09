//
//  Metrics.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import VerificationEngine

struct Metric {
    
    enum MetricsStatus: String {
        case unknown = "Unknown"
        
        case Verified = "Verified"
        case Unverified = "Unverified"
    }
    
    var timestamp: String
    
    var verifierId: String
    var organizationId: String
    var customerId: String
    
    var type: String?
    var spec: String
    
    var status: String
    
    var issuerId: String?
    var issuerName: String?
    
    var rawDictionary = [String: String]()
    
    init?(status: String?, type: String?, spec: String, issuerId: String?, issuerName: String? = nil) {
        let date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour], from: Date()))
        
        let currentOrganization = DataStore.shared.currentOrganization
        
        guard let date = date,
              let verifierId = currentOrganization?.credential?.id,
              let organizationId = currentOrganization?.credential?.credentialSubject?["organizationId"] as? String,
              let status = status,
              let customerId = currentOrganization?.credential?.credentialSubject?["customerId"] as? String else {
                  return nil
              }
        
        
        self.timestamp = Date.stringForDate(date: date, dateFormatPattern: .timestampFormat, locale: Locale(identifier: "en_US"))
        self.rawDictionary["timestamp"] = self.timestamp
        
        self.verifierId = verifierId
        self.rawDictionary["verifierId"] = verifierId
        
        self.organizationId = organizationId
        self.rawDictionary["organizationId"] = organizationId
        
        self.customerId = customerId
        self.rawDictionary["customerId"] = customerId
        
        self.type = type
        self.rawDictionary["type"] = type
        
        self.spec = spec
        self.rawDictionary["spec"] = spec
        
        self.status = status
        self.rawDictionary["status"] = status
        
        self.issuerId = issuerId
        self.rawDictionary["issuerId"] = issuerId
        
        self.issuerName = issuerName
        self.rawDictionary["issuerName"] = issuerName
    }
    
    init?(value: [String: String]) {
        let value = value.mapValues { $0 is NSNull ? nil : $0 }
        rawDictionary = value.compactMapValues { $0 }
        
        guard let timestamp = rawDictionary["timestamp"],
              let verifierId = rawDictionary["verifierId"],
              let organizationId = rawDictionary["organizationId"],
              let status = rawDictionary["status"],
              let customerId = rawDictionary["customerId"],
              let spec = rawDictionary["spec"] else {
                  return nil
              }
        
        self.timestamp = timestamp
        self.verifierId = verifierId
        self.organizationId = organizationId
        
        self.status = status
        
        self.customerId = customerId
        
        self.type = rawDictionary["type"]
        self.spec = spec
        
        self.issuerId = rawDictionary["issuerId"]
        self.issuerName = rawDictionary["issuerName"]
    }
    
}
