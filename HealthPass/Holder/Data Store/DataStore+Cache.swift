//
//  DataStore+Cache.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import VerificationEngine

extension DataStore {
    
    // MARK: - Issuer Properties
    
    //SHC
    var allJWKSet: [JWKSet]? {
        get {
            return allJWKSetData?.compactMap { try? JSONDecoder().decode(JWKSet.self, from: $0) }
        }
    }
    
    var allJWKSetData: [Data]? {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kJWKSetArray.rawValue)
        } get {
            return UserDefaults.standard.array(forKey: UserDefaultsKey.kJWKSetArray.rawValue) as? [Data]
        }
    }
    
    //DCC
    var allIssuerKeyData: [Data]? {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kIssuerKeyArray.rawValue)
        } get {
            return UserDefaults.standard.array(forKey: UserDefaultsKey.kIssuerKeyArray.rawValue) as? [Data]
        }
    }
    
    var allIssuerKey: [IssuerKey]? {
        get {
            return allIssuerKeyData?.compactMap { try? JSONDecoder().decode(IssuerKey.self, from: $0) }
        }
    }
    
    // MARK: - VC, IDHP, GHP Schema Methods
    
    mutating func addNewSchema(schema: Schema) {
        guard let schemaDictionary = schema.rawDictionary else { return }
        
        guard let allSchema = allSchema else {
            allSchemaDictionary = [schemaDictionary]
            return
        }
        
        guard allSchema.contains(where: { $0.id == schema.id }) else {
            allSchemaDictionary?.append(schemaDictionary)
            return
        }
    }
    
    func getSchema(for credental: Credential) -> Schema? {
        guard let schemaId = credental.credentialSchema?.id else {
            return nil
        }
        
        return getSchema(for: schemaId)
    }
    
    func getSchema(for schemaId: String) -> Schema? {
        guard let allSchema = allSchema else {
            return nil
        }
        
        return allSchema.filter { $0.id == schemaId }.last
    }
    
    mutating func deleteAllSchemas() {
        guard let allSchema = allSchema, !(allSchema.isEmpty) else { return }
        
        allSchemaDictionary?.removeAll()
    }
    
    
    // MARK: - VC, IDHP, GHP Issuer Methods
    
    mutating func addNewIssuer(issuer: Issuer) {
        guard let issuerDictionary = issuer.rawDictionary else { return }
        
        guard let allIssuer = allIssuer else {
            allIssuerDictionary = [issuerDictionary]
            return
        }
        
        guard allIssuer.contains(where: { $0.id == issuer.id }) else {
            allIssuerDictionary?.append(issuerDictionary)
            return
        }
        
    }
    
    func getIssuer(for credental: Credential) -> Issuer? {
        guard let issuerId = credental.issuer else {
            return nil
        }
        
        return getIssuer(for: issuerId)
    }
    
    func getIssuer(for issuerId: String) -> Issuer? {
        guard let allIssuer = allIssuer else {
            return nil
        }
        
        return allIssuer.filter { $0.id == issuerId }.last
    }
    
    mutating func overwriteIssuers(issuers: [Issuer]) {
        let issuerDictionaries = issuers.compactMap({ $0.rawDictionary })
        
        guard !(issuerDictionaries.isEmpty) else { return }
        
        deleteAllIssuers()
        
        allIssuerDictionary = issuerDictionaries
    }
    
    mutating func deleteAllIssuers() {
        allIssuerDictionary?.removeAll()
        allIssuerDictionary = nil
    }
    
    // MARK: - VC, IDHP, GHP Issuer Metadata Methods
    
    mutating func addNewIssuerMetadata(issuerMetadata: IssuerMetadata) {
        guard let issuerMetadataDictionary = issuerMetadata.rawDictionary else { return }
        
        guard let allIssuerMetadata = allIssuerMetadata else {
            allIssuerMetadataDictionary = [issuerMetadataDictionary]
            return
        }
        
        guard allIssuerMetadata.contains(where: { $0.id == issuerMetadata.id }) else {
            allIssuerMetadataDictionary?.append(issuerMetadataDictionary)
            return
        }
        
    }
    
    func getIssuerMetadata(for credental: Credential) -> IssuerMetadata? {
        guard let issuerId = credental.issuer else {
            return nil
        }
        
        return getIssuerMetadata(for: issuerId)
    }
    
    func getIssuerMetadata(for issuerId: String) -> IssuerMetadata? {
        guard let allIssuerMetadata = allIssuerMetadata else {
            return nil
        }
        
        return allIssuerMetadata.filter { $0.id == issuerId }.last
    }
    
    mutating func deleteAllIssuerMetadata() {
        guard let allIssuerMetadata = allIssuerMetadata, !(allIssuerMetadata.isEmpty) else { return }
        
        allIssuerMetadataDictionary?.removeAll()
    }
    
    // MARK: - DCC Issuer Methods
    
    mutating func addIssuerKeys(issuerKeys: [IssuerKey]) {
        let issuerKeyData = issuerKeys.compactMap({ try? JSONEncoder().encode($0) })
        
        guard let _ = allIssuerKey else {
            allIssuerKeyData = issuerKeyData
            return
        }
        
        allIssuerKeyData?.append(contentsOf: issuerKeyData)
    }
    
    func getIssuerKey(for keyId: String) -> [IssuerKey]? {
        guard let allIssuerKey = allIssuerKey else {
            return nil
        }
        
        return allIssuerKey.filter { $0.kid == keyId }
    }
    
    mutating func overwriteIssuerKeys(issuerKeys: [IssuerKey]) {
        let issuerKeyData = issuerKeys.compactMap({ try? JSONEncoder().encode($0) })
        
        guard !(issuerKeyData.isEmpty) else { return }
        
        deleteAllIssuerKey()
        
        allIssuerKeyData = issuerKeyData
    }
    
    mutating func deleteAllIssuerKey() {
        allIssuerKeyData?.removeAll()
        allIssuerKeyData = nil
    }
    
    // MARK: - SHC Issuer Methods
    
    mutating func addJWKSet(jwkSet: [JWKSet]) {
        let jwkSetData = jwkSet.compactMap({ try? JSONEncoder().encode($0) })
        
        guard let _ = allJWKSet else {
            allJWKSetData = jwkSetData
            return
        }
        
        allJWKSetData?.append(contentsOf: jwkSetData)
    }
    
    func getJWKSet(for url: String) -> [JWKSet]? {
        guard let allJWKSet = allJWKSet else {
            return nil
        }
        
        return allJWKSet.filter { $0.url == url }
    }
    
    mutating func overwriteJWKSet(jwkSet: [JWKSet]) {
        let jwkSetData = jwkSet.compactMap({ try? JSONEncoder().encode($0) })
        
        guard !(jwkSetData.isEmpty) else { return }
        
        deleteAllJWKSet()
        
        allJWKSetData = jwkSetData
    }
    
    mutating func deleteAllJWKSet() {
        allJWKSetData?.removeAll()
        allJWKSetData = nil
    }
    
}
