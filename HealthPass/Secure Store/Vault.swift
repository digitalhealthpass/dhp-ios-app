//
//  Vault.swift
//  Secure Store
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Security

struct Vault {
    private let vaultQueryable: VaultQueryable
    
    init(vaultQueryable: VaultQueryable) {
        self.vaultQueryable = vaultQueryable
    }
    
    func setPayload(_ payload: [String : Any], for account: String) throws {
        guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: payload, requiringSecureCoding: true) else { throw VaultError.payloadToDataConversionError }
        try setData(encodedData, for: account)
    }
    
    func addPayload(_ payload: [String : Any], for account: String) throws {
        guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: payload, requiringSecureCoding: true) else { throw VaultError.payloadToDataConversionError }
        try addData(encodedData, for: account)
    }
    
    func getPayload(for account: String) throws -> [String : Any]? {
        guard
          let data = try getData(for: account),
          let payload = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String : Any]
        else { throw VaultError.dataToPayloadConversionError }
        
        return payload
    }
    
    func updatePayload(_ payload: [String : Any], for account: String) throws {
        guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: payload, requiringSecureCoding: true) else { throw VaultError.payloadToDataConversionError }
        try updateData(encodedData, for: account)
    }
    
    func removePayload(for account: String) throws {
        var query = vaultQueryable.query
        query[String(kSecAttrAccount)] = account
      
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw error(from: status) }
    }
    
    // MARK:- Private
    
    private func setData(_ data: Data, for account: String) throws {
        var query = vaultQueryable.query
        query[String(kSecAttrAccount)] = account
        
        var status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            var attributes = [String : Any]()
            attributes[String(kSecValueData)] = data
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if status != errSecSuccess { throw error(from: status) }
        case errSecItemNotFound:
            query[String(kSecValueData)] = data
            status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess { throw error(from: status) }
        default:
            throw error(from: status)
        }
    }
    
    private func addData(_ data: Data, for account: String) throws {
        var query = vaultQueryable.query
        query[String(kSecAttrAccount)] = account
        
        var status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            throw VaultError.duplicate
        case errSecItemNotFound:
            query[String(kSecValueData)] = data
            status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess { throw error(from: status) }
        default:
            throw error(from: status)
        }
    }
    
    private func getData(for account: String) throws -> Data? {
        var query = vaultQueryable.query
        query[String(kSecMatchLimit)] = kSecMatchLimitOne
        query[String(kSecReturnAttributes)] = kCFBooleanTrue
        query[String(kSecReturnData)] = kCFBooleanTrue
        query[String(kSecAttrAccount)] = account
        
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, $0)
        }
        
        switch status {
        case errSecSuccess:
            guard let queriedItem = queryResult as? [String : Any] else { return nil }
            return queriedItem[String(kSecValueData)] as? Data
            
        case errSecItemNotFound: return nil
        default: throw error(from: status)
        }
    }
    
    private func updateData(_ data: Data, for account: String) throws {
        var query = vaultQueryable.query
        query[String(kSecAttrAccount)] = account
        
        var status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            var attributes = [String : Any]()
            attributes[String(kSecValueData)] = data
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if status != errSecSuccess { throw error(from: status) }
        default:
            throw error(from: status)
        }
    }
    
    private func error(from status: OSStatus) -> VaultError {
      let message = SecCopyErrorMessageString(status, nil) as String? ?? NSLocalizedString("Unhandled Error", comment: "")
      return VaultError.unhandledError(message: message)
    }
}
