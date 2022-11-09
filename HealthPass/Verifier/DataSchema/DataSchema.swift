//
//  DataSchema.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

enum CredentialSubjectType: String {
    case profile
    case id
    
    var displayValue: String {
        switch self {
        case .profile:
            return "data.schemaProfile".localized
        case .id:
            return "data.schemaID".localized
        }
    }
}
