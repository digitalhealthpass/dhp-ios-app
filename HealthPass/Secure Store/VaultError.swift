//
//  VaultError.swift
//  Secure Store
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

public enum VaultError: Error {
    case payloadToDataConversionError
    case dataToPayloadConversionError
    case duplicate
    case unhandledError(message: String)
}

extension VaultError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .payloadToDataConversionError: return NSLocalizedString("Failed to convert the payload into data.", comment: "")
        case .dataToPayloadConversionError: return NSLocalizedString("Failed to convert the data into the payload.", comment: "")
        case .duplicate: return NSLocalizedString("The item already exists.", comment: "")
        case .unhandledError(let message): return NSLocalizedString(message, comment: "")
        }
    }
}
