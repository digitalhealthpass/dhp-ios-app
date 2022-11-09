//
//  User.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit

struct User {
    var exp: String?
    var tenant: String?
    var iat: String?
    var email: String?
    var name: String?
    var sub: String?
    var email_verified: String?
    var given_name: String?
    var family_name: String?
    
    init(value: [String: Any]) {
        exp = value["exp"] as? String
        tenant = value["tenant"] as? String
        iat = value["iat"] as? String
        email = value["email"] as? String
        name = value["name"] as? String
        sub = value["sub"] as? String
        email_verified = value["email_verified"] as? String
        given_name = value["given_name"] as? String
        family_name = value["family_name"] as? String
    }
}
