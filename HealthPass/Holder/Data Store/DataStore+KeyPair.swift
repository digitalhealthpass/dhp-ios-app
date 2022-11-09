//
//  DataStore.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire

// MARK: - KeyPair management Extension

extension DataStore {
    
    mutating func migrateKeyPair(_ keyPairArray: [AsymmetricKeyPair], completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        
        var allKeyPairArray = data[SecureStoreKey.kKeyPair.rawValue] as? [[String: Any]] ?? [[String: Any]]()
        let migratingKeyPairArray = keyPairArray.compactMap({ $0.rawDictionary })
        allKeyPairArray.append(contentsOf: migratingKeyPairArray)
        
        data[SecureStoreKey.kKeyPair.rawValue] = allKeyPairArray
        
        updateSecureStoreData(data: data, with: completion)
    }

    mutating func saveKeyPair(_ keyPairDictionar: [String: Any], completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        
        var allKeyPairArray = data[SecureStoreKey.kKeyPair.rawValue] as? [[String: Any]] ?? [[String: Any]]()
        allKeyPairArray.append(keyPairDictionar)
        
        data[SecureStoreKey.kKeyPair.rawValue] = allKeyPairArray
        
        updateSecureStoreData(data: data, with: completion)
    }
    
    mutating func deletekeyPair(_ keyPairDictionar: [String: Any], completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        
        var filteredKeyPairArray = [[String: Any]]()
        if let allKeyPairArray = data[SecureStoreKey.kKeyPair.rawValue] as? [[String: Any]] {
            filteredKeyPairArray = allKeyPairArray.filter {
                ($0["id"] as? String != keyPairDictionar["id"] as? String)
            }
        }
        
        data[SecureStoreKey.kKeyPair.rawValue] = filteredKeyPairArray
        
        updateSecureStoreData(data: data, with: completion)
    }
    
    mutating func deleteAllUserKeyPair(completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        data[SecureStoreKey.kKeyPair.rawValue] = nil
        
        updateSecureStoreData(data: data, with: completion)
    }
    
}
