//
//  VerificationResult.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct VerificationResult {
    var result: Bool
    var message: String?
    
    init(result: Bool, message: String) {
        self.result = result
        self.message = message
    }
}
