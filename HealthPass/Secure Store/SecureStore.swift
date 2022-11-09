//
//  SecureStore.swift
//  Secure Store
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

/**
A collection of helper functions for saving, retrieving, updating and deleting data in the keychain.
*/
public struct SecureStore {
    /**
     Adds data to the keychain based on a user account and service.  If the item already exists a duplicate error is thrown.
     
     - parameter data: the dictionary to be stored in the keychain
     - parameter forUserAccount: the account in which to store data
     - parameter inService: the service in which to store the data
     
     - throws: keychain errors
     */
    public static func addData(data: [String : Any], forUserAccount userAccount: String, inService service: String) throws {
        let store = Vault(vaultQueryable: GenericPasswordQueryable(service: service))
        try store.addPayload(data, for: userAccount)
    }
    
    /**
     Saves the data to the keychain. If the item already exists it will be updated, otherwise it will be added.
     
     - parameter data: the dictionary to be stored in the keychain
     - parameter forUserAccount: the account in which to store data
     - parameter inService: the service in which to store the data
     
     - throws: keychain errors
     */
    public static func saveData(data: [String: Any], forUserAccount userAccount: String, inService service: String) throws {
        let store = Vault(vaultQueryable: GenericPasswordQueryable(service: service))
        try store.setPayload(data, for: userAccount)
    }
    
    /**
     Updates the data held within the account and service in the keychain.
     
     - parameter data: the dictionary to be updated in the keychain
     - parameter forUserAccount: the account in which to update data
     - parameter inService: the service in which to update the data
     
     - throws: keychain errors
     */
    public static func updateData(data: [String: Any], forUserAccount userAccount: String, inService service: String) throws {
        let store = Vault(vaultQueryable: GenericPasswordQueryable(service: service))
        try store.updatePayload(data, for: userAccount)
    }
    
    /**
     Retrieves the data associated with the account and service.
     
     - parameter data: the dictionary to be stored in the keychain
     - parameter forUserAccount: the account in which to store data
     - parameter inService: the service in which to store the data
     
     - returns the dictionary for the userAccount and service
     */
    public static func loadDataForUserAccount(userAccount: String, inService service: String) -> [String: Any]? {
        let store = Vault(vaultQueryable: GenericPasswordQueryable(service: service))
        guard let data = try? store.getPayload(for: userAccount) else { return nil }
        return data
    }
    
    /**
     Removes the data for the given account and service.
     
     - parameter forUserAccount: the account in which to remove
     - parameter inService: the service in which to remove
     
     - throws: keychain errors
     */
    public static func deleteDataForUserAccount(userAccount: String, inService service: String) throws {
        let store = Vault(vaultQueryable: GenericPasswordQueryable(service: service))
        try store.removePayload(for: userAccount)
    }
}
