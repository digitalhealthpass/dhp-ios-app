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

// MARK: - Contact management Extension

extension DataStore {
    
    func getContact(for cred: String?) -> Contact? {
        guard let cred = cred else {
            return nil
        }
        
        guard let requiredContactProfileId = userContacts.compactMap({ $0.profilePackage?.credential?.id }).filter({ $0.contains(cred) }).first else {
            return nil
        }
        
        let requiredContact = userContacts.filter({ $0.profilePackage?.credential?.id == requiredContactProfileId }).first
        
        return requiredContact
    }
    
    mutating func migrateContact(_ contacts: [Contact], completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        
        var allContactArray = data[SecureStoreKey.kContact.rawValue] as? [[String: Any]] ?? [[String: Any]]()
        let migratingContacts = contacts.compactMap({ $0.rawDictionary })
        allContactArray.append(contentsOf: migratingContacts)
        
        data[SecureStoreKey.kContact.rawValue] = allContactArray
        
        updateSecureStoreData(data: data, with: completion)
    }
    
    mutating func saveContact(_ contact: Contact, completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        
        var allContactArray = data[SecureStoreKey.kContact.rawValue] as? [[String: Any]] ?? [[String: Any]]()
        allContactArray.append(contact.rawDictionary!)
        
        data[SecureStoreKey.kContact.rawValue] = allContactArray
        
        updateSecureStoreData(data: data, with: completion)
    }
    
    mutating func updateContact(_ contact: Contact, completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        
        var allContactArray = data[SecureStoreKey.kContact.rawValue] as? [[String: Any]] ?? [[String: Any]]()
        
        var allContacts = allContactArray.compactMap({ Contact(value: $0) })
        allContacts = allContacts.filter { $0.idCredential?.id != contact.idCredential?.id }
        allContacts.append(contact)
        
        allContactArray = allContacts.compactMap({ $0.rawDictionary })
        
        data[SecureStoreKey.kContact.rawValue] = allContactArray
        
        updateSecureStoreData(data: data, with: completion)
    }
    
    mutating func deleteContact(_ contact: Contact, completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        
        var filteredContacts = [Contact]()
        if let allContactArray = data[SecureStoreKey.kContact.rawValue] as? [[String: Any]] {
            let allContact = allContactArray.map { Contact(value: $0) }
            filteredContacts = allContact.filter { $0.idPackage?.credential?.id != contact.idPackage?.credential?.id }
        }
        
        let filteredContactDictionary = filteredContacts.compactMap { $0.rawDictionary }
        data[SecureStoreKey.kContact.rawValue] = filteredContactDictionary
        
        //Delete the upload details file too
        var filteredContactUploadDetails = [ContactUploadDetails]()
        if let allContactUploadDetailsArray = data[SecureStoreKey.kContactUploadDetails.rawValue] as? [[String: Any]] {
            let allContactUploadDetails = allContactUploadDetailsArray.map { ContactUploadDetails(value: $0) }
            filteredContactUploadDetails = allContactUploadDetails.filter { $0.contactID != contact.idPackage?.credential?.id }
        }
        
        let filteredContactUploadDetailsDictionary = filteredContactUploadDetails.compactMap { $0.rawDictionary }
        data[SecureStoreKey.kContactUploadDetails.rawValue] = filteredContactUploadDetailsDictionary
        
        //Delete the associated key with the contact
        if let contactKey = contact.idPackage?.credential?.extendedCredentialSubject?.id,
           let associatedKey = self.userKeyPairs.filter({ $0.publickey == contactKey }).first,
           let associatedKeyDictionary = associatedKey.rawDictionary {
            
            var filteredKeyPairArray = [[String: Any]]()
            if let allKeyPairArray = data[SecureStoreKey.kKeyPair.rawValue] as? [[String: Any]] {
                filteredKeyPairArray = allKeyPairArray.filter {
                    ($0["id"] as? String != associatedKeyDictionary["id"] as? String)
                }
                
            }
            
            data[SecureStoreKey.kKeyPair.rawValue] = filteredKeyPairArray
        }
        
        
        updateSecureStoreData(data: data, with: completion)
    }
    
    
    mutating func deleteAllUserContact(completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        data[SecureStoreKey.kContact.rawValue] = nil
        
        updateSecureStoreData(data: data, with: completion)
    }
    
}

extension DataStore {
    
    mutating func migrateContactUploadDetails(_ contactUploadDetails: [ContactUploadDetails], completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        
        var allContactUploadDetailsArray = data[SecureStoreKey.kContactUploadDetails.rawValue] as? [[String: Any]] ?? [[String: Any]]()
        let migratingContactUploadDetails = contactUploadDetails.compactMap({ $0.rawDictionary })
        allContactUploadDetailsArray.append(contentsOf: migratingContactUploadDetails)
        
        data[SecureStoreKey.kContactUploadDetails.rawValue] = allContactUploadDetailsArray
        
        updateSecureStoreData(data: data, with: completion)
    }
    
    mutating func saveContactUploadDetails(_ contactUploadDetails: ContactUploadDetails, completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        
        var allContactUploadDetailsArray = data[SecureStoreKey.kContactUploadDetails.rawValue] as? [[String: Any]] ?? [[String: Any]]()
        allContactUploadDetailsArray = allContactUploadDetailsArray.filter { $0["contactID"] as? String !=  contactUploadDetails.contactID }
        allContactUploadDetailsArray.append(contactUploadDetails.rawDictionary!)
        
        data[SecureStoreKey.kContactUploadDetails.rawValue] = allContactUploadDetailsArray
        
        updateSecureStoreData(data: data, with: completion)
    }
    
}
