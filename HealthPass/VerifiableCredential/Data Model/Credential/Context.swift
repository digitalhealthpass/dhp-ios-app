//
//  Context.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Context: Codable {
    enum CodingKeys: String, CodingKey {
        case cred
    }
    
    public var cred: String?
    
}
