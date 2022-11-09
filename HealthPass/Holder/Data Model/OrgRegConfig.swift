//
//  OrgRegConfig.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct OrgRegConfig {
    var type: String?
    var org: String?
    var flow: OrgRegFlow?
    var userAgreement: String?
    var registrationForm: [String: Any]?
    
    init(value: [String: Any]) {
        type = value["type"] as? String
        org = value["org"] as? String
        
        if let flowDictionary = value["flow"] as? [String: Any] {
            flow = OrgRegFlow(value: flowDictionary)
        }
        
        userAgreement = value["userAgreement"] as? String
        
        if let nameDictionary = value["name"] as? [String: Any] {
            registrationForm = nameDictionary
        } else {
            registrationForm = value["registrationForm"] as? [String: Any]
        }
    }
}

struct OrgRegFlow {
    var registrationCodeAuth: Bool
    var mfaAuth: Bool
    var showUserAgreement: Bool
    var showRegistrationForm: Bool
    
    init(value: [String: Any]) {
        registrationCodeAuth = value["registrationCodeAuth"] as? Bool ?? false
        mfaAuth = value["mfaAuth"] as? Bool ?? false
        showUserAgreement = value["showUserAgreement"] as? Bool ?? false
        showRegistrationForm = value["showRegistrationForm"] as? Bool ?? false
    }
}
