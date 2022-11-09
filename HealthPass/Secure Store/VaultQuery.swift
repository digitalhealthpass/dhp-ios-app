//
//  VaultQuery.swift
//  Secure Store
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

protocol VaultQueryable {
    var query: [String : Any] { get }
}

struct GenericPasswordQueryable {
    let service: String
    let accessGroup: String?
    
    init(service: String, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }
}

extension GenericPasswordQueryable: VaultQueryable {
    var query: [String : Any] {
        var query = [String : Any]()
        query[String(kSecClass)] = kSecClassGenericPassword
        query[String(kSecAttrService)] = service
        
        #if !targetEnvironment(simulator)
        if let accessGroup = self.accessGroup {
            query[String(kSecAttrAccessGroup)] = accessGroup
        }
        #endif
        
        return query
    }
}
