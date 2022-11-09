//
//  OptionalRevokedCredential.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct RevokeStatus: Codable {
    var exists: Bool?
    var id: String?
    var reason: String?
    var createdAt: Int?
    var updatedAt: Int?
    var createdBy: String?
    
    var isRevoked: Bool {
        guard let exists = exists else {
            return true
        }
        
        return exists
    }
}
