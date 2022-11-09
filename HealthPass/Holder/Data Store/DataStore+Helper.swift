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
import SecureStore

// MARK: - Locksmith Helper Extension

extension DataStore {
    
    public func getSecureStoreData() -> [String : Any] {
        return SecureStore.loadDataForUserAccount(userAccount: SecureStoreKey.kAccount.rawValue, inService: SecureStoreKey.kAccount.rawValue) ?? [String : Any]()
    }
    
    internal func setSecureStoreData(data: [String : Any], with completion: ((Result<Bool>) -> Void)? = nil) {
        do {
            try SecureStore.saveData(data: data, forUserAccount: SecureStoreKey.kAccount.rawValue, inService: SecureStoreKey.kAccount.rawValue)
            completion?(.success(true))
        } catch {
            print(error)
            completion?(.failure(error))
        }
    }
    
    internal func updateSecureStoreData(data: [String: Any], with completion: ((Result<Bool>) -> Void)? = nil) {
        do {
            try SecureStore.updateData(data: data, forUserAccount: SecureStoreKey.kAccount.rawValue, inService: SecureStoreKey.kAccount.rawValue)
            completion?(.success(true))
        } catch {
            print(error)
            completion?(.failure(error))
        }
    }
    
    public func resetKeychain(with completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        
        DataStore.shared.didGetStarted = false
        DataStore.shared.didFinishPinSetup = false
        
        data[SecureStoreKey.kUserPIN.rawValue] = nil
        data[SecureStoreKey.kPackages.rawValue] = nil
        data[SecureStoreKey.kKeyPair.rawValue] = nil
        data[SecureStoreKey.kContact.rawValue] = nil
        data[SecureStoreKey.kContactUploadDetails.rawValue] = nil
        
        updateSecureStoreData(data: data, with: completion)
    }
    
    public func resetCache() {
        DataStore.shared.deleteAllSchemas()
        DataStore.shared.deleteAllIssuerMetadata()
        DataStore.shared.deleteAllJWKSet()
        DataStore.shared.deleteAllIssuerKey()
        DataStore.shared.deleteAllIssuers()
    }
    
}
