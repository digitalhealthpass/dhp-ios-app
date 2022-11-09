//
//  DataStore+Cache.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import VerifiableCredential
import VerificationEngine

extension DataStore {
   
    // MARK: - Issuer Properties
    
    //VC, IDHP, GHP
    var allIssuer: [Issuer]? {
        get {
            return allIssuerDictionary?.compactMap { Issuer(value: $0) }
        }
    }
    
    var allIssuerDictionary: [[String: Any]]? {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kIssuerArray.rawValue)
        } get {
            return UserDefaults.standard.array(forKey: UserDefaultsKey.kIssuerArray.rawValue) as? [[String: Any]]
        }
    }
    
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
    var allIssuerKey: [IssuerKey]? {
        get {
            return allIssuerKeyData?.compactMap { try? JSONDecoder().decode(IssuerKey.self, from: $0) }
        }
    }
    
    var allIssuerKeyData: [Data]? {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kIssuerKeyArray.rawValue)
        } get {
            return UserDefaults.standard.array(forKey: UserDefaultsKey.kIssuerKeyArray.rawValue) as? [Data]
        }
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

extension DataStore {
    
    // MARK: - Schema Properties
    
    var allSchema: [Schema]? {
        get {
            return allSchemaDictionary?.compactMap { Schema(value: $0) }
        }
    }
    
    var allSchemaDictionary: [[String: Any]]? {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kSchemaArray.rawValue)
        } get {
            return UserDefaults.standard.array(forKey: UserDefaultsKey.kSchemaArray.rawValue) as? [[String: Any]]
        }
    }
    
    // MARK: - Schema Methods
    
    mutating
    func addNewSchema(schema: Schema) {
        guard let schemaDictionary = schema.rawDictionary else {
            return
        }
        
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
        guard let schemaId = credental.credentialSchema?.id, let allSchema = allSchema else {
            return nil
        }
        
        return allSchema.filter { $0.id == schemaId }.last
    }
    
    mutating
    func deleteAllSchemas() {
        guard let allSchema = allSchema, !(allSchema.isEmpty) else {
            return
        }
        
        allSchemaDictionary?.removeAll()
    }
    
}

extension DataStore {
    
    // MARK: - Issuer Metadata Properties
    
    var allIssuerMetadata: [IssuerMetadata]? {
        get {
            return allIssuerMetadataDictionary?.compactMap { IssuerMetadata(value: $0) }
        }
    }
    
    var allIssuerMetadataDictionary: [[String: Any]]? {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kIssuerMetadataArray.rawValue)
        } get {
            return UserDefaults.standard.array(forKey: UserDefaultsKey.kIssuerMetadataArray.rawValue) as? [[String: Any]]
        }
    }
    
    // MARK: - Issuer Metadata Methods
    
    mutating
    func addNewIssuerMetadata(issuerMetadata: IssuerMetadata) {
        guard let issuerMetadataDictionary = issuerMetadata.rawDictionary else {
            return
        }
        
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
    
    mutating
    func deleteAllIssuerMetadata() {
        guard let allIssuerMetadata = allIssuerMetadata, !(allIssuerMetadata.isEmpty) else {
            return
        }
        
        allIssuerMetadataDictionary?.removeAll()
    }
    
}

extension DataStore {
    
    // MARK: - VerifierConfiguration Properties
    
    var allVerifierConfiguration: [VerifierConfiguration]? {
        get {
            return allVerifierConfigurationDictionary?.compactMap { dictionary in
                guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted) else {
                    return nil
                }
                
                return try? VerifierConfiguration(data: data)
            }
        }
    }
    
    var allVerifierConfigurationDictionary: [[String: Any]]? {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kVerifierConfigurationArray.rawValue)
        } get {
            return UserDefaults.standard.array(forKey: UserDefaultsKey.kVerifierConfigurationArray.rawValue) as? [[String: Any]]
        }
    }
    
    // MARK: - VerifierConfiguration Methods
    
    mutating
    func addNewVerifierConfiguration(verifierConfiguration: VerifierConfiguration) {
        guard let verifierConfigurationData = try? verifierConfiguration.jsonData(),
              let verifierConfigurationDictionary = try? JSONSerialization.jsonObject(with: verifierConfigurationData, options: []) as? [String: Any] else {
            return
        }
        
        allVerifierConfigurationDictionary?.removeAll(where: { verifierConfiguration.id == $0["id"] as? String })
        
        guard allVerifierConfiguration != nil else {
            allVerifierConfigurationDictionary = [verifierConfigurationDictionary]
            return
        }
        
        allVerifierConfigurationDictionary?.append(verifierConfigurationDictionary)
        
    }
    
    func getVerifierConfiguration(for id: String) -> VerifierConfiguration? {
        guard let allVerifierConfiguration = allVerifierConfiguration else {
            return nil
        }
        
        return allVerifierConfiguration.filter { $0.id == id }.last
    }
    
    func shouldRefreshCache(for verifierConfiguration: VerifierConfiguration) -> Bool {
        guard let configCachedAt = verifierConfiguration.cachedAt else {
            return true
        }
        
        let currentDate = Date()
        let cacheTimeDifference = currentDate.timeIntervalSinceReferenceDate - configCachedAt.timeIntervalSinceReferenceDate
        
        guard let refresh = verifierConfiguration.refresh, cacheTimeDifference < TimeInterval(refresh) else {
            return true
        }
        
        return false
    }

    mutating
    func deleteAllVerifierConfiguration() {
        guard let allVerifierConfiguration = allVerifierConfiguration, !(allVerifierConfiguration.isEmpty) else {
            return
        }
        
        allVerifierConfigurationDictionary?.removeAll()
    }
    
}
