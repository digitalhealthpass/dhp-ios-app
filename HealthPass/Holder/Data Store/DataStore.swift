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
import VerificationEngine

enum SecureStoreKey: String {
    case kAccount = "IBM.HealthPass"
    
    case kUserPIN = "userPIN"
    
    case kAccessToken = "accessToken"
    case kLoginTimeStamp = "loginTime"
    case kExpiresIn = "expires_in"
    
    case kPackages = "kPackages"
    case kKeyPair = "kKeyPair"
    case kContact = "kContact"
    case kContactUploadDetails = "kContactUploadDetails"
}

enum UserDefaultsKey: String {
    case kdidAcceptPrivacy = "IBM.UserDefaults.didAcceptPrivacy"
    case kdidTermsConditions = "IBM.UserDefaults.didTermsConditions"
    case kdidGetStarted = "IBM.UserDefaults.didGetStarted"
    case kdidFinishPinSetup = "IBM.UserDefaults.didFinishPinSetup"
    case kdidSelectDataCenter = "IBM.UserDefaults.didSelectDataCenter"
    
    case kSchemaArray = "IBM.UserDefaults.schemaArray"
    case kIssuerArray = "IBM.UserDefaults.issuerArray"
    case kIssuerMetadataArray = "IBM.UserDefaults.issuerMetadataArray"
    
    case kIBMRTOReminder = "IBM.UserDefaults.RTOReminder"
    
    case kCameraAccess = "IBM.UserDefaults.cameraAccess"
    
    case kRevocationVerification = "IBM.UserDefaults.revocationVerification"
    case kCacheRules = "IBM.UserDefaults.cacheRules"
    case kJWKSetArray = "IBM.UserDefaults.jwkSetArray"
    case kIssuerKeyArray = "IBM.UserDefaults.issuerKeyArray"
    
    case kLastVersionPromptedForReview = "lastVersionPromptedForReview"

}

public let kUTTypeHPZipArchive: CFString = "com.IBM.HealthPass.Holder.BackupArchive" as CFString


struct DataStore {
    
    static var shared = DataStore()
    
    // MARK: - IBM RTO Connection Properties
    
    let IBM_RTO_ORG_PROD = "ibm-rto"
    let IBM_RTO_REG_CODE_PROD = "IBMEMPLOYEE"
    
    let IBM_RTO_CRED_TYPE_PROD = ["Vaccination Card", "Vaccination Credential"]
    let IBM_RTO_SCHEMA_NAME_PROD = ["GHP Vaccination Credential", "GHP Vaccination Credential"]
    let IBM_RTO_ISSUER_NAME_PROD = ["IBM Digital HealthPass Issuer", "CLXHealthPaper"]
    
    var IBM_RTO_Reminder: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kIBMRTOReminder.rawValue)
        } get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKey.kIBMRTOReminder.rawValue)
        }
    }
    
    // MARK: - App level Properties
    
    var cameraAccess: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kCameraAccess.rawValue)
        } get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKey.kCameraAccess.rawValue)
        }
    }
    
    // MARK: - Issuer Properties
    
    // MARK: - Verification Rules Properties
    
    var revocationVerification: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kRevocationVerification.rawValue)
        } get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKey.kRevocationVerification.rawValue)
        }
    }
    
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
    
    // MARK: - Application Level Properties
    
    var didAcceptPrivacy: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kdidAcceptPrivacy.rawValue)
        } get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKey.kdidAcceptPrivacy.rawValue)
        }
    }
    
    var didAgreeTermsConditions: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kdidTermsConditions.rawValue)
        } get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKey.kdidTermsConditions.rawValue)
        }
    }
    
    var didGetStarted: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kdidGetStarted.rawValue)
        } get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKey.kdidGetStarted.rawValue)
        }
    }
    
    var didFinishPinSetup: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kdidFinishPinSetup.rawValue)
        } get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKey.kdidFinishPinSetup.rawValue)
        }
    }
    
    var didSelectDataCenter: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kdidSelectDataCenter.rawValue)
        } get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKey.kdidSelectDataCenter.rawValue)
        }
    }
    
    /// Current deeplink action
    var deepLinkAction: String?
    
    /// Current import URL
    var importURL: URL?
    
    /// query parameters for the current deeplink action
    var deepLinkQueries: [String : String]?
    
    var didLoadHomeController: Bool = false
    
    // MARK: - Login Properties
    
    var hasPINEnabled: Bool {
        return (userPIN != nil)
    }
    
    var userPIN: [Int: Int]? {
        get {
            let data = getSecureStoreData()
            return data[SecureStoreKey.kUserPIN.rawValue] as? [Int: Int]
        } set {
            var data = getSecureStoreData()
            data[SecureStoreKey.kUserPIN.rawValue] = newValue
            setSecureStoreData(data: data)
        }
    }
    
    var userAccessToken: String? {
        get {
            let data = getSecureStoreData()
            return data[SecureStoreKey.kAccessToken.rawValue] as? String
        } set {
            var data = getSecureStoreData()
            data[SecureStoreKey.kAccessToken.rawValue] = newValue
            setSecureStoreData(data: data)
        }
    }
    
    var loginTimeStamp: String? {
        get {
            let data = getSecureStoreData()
            return data[SecureStoreKey.kLoginTimeStamp.rawValue] as? String
        } set {
            var data = getSecureStoreData()
            data[SecureStoreKey.kLoginTimeStamp.rawValue] = newValue
            setSecureStoreData(data: data)
        }
    }
    
    var loginExpiresIn: Double? {
        get {
            let data = getSecureStoreData()
            return data[SecureStoreKey.kExpiresIn.rawValue] as? Double
        } set {
            var data = getSecureStoreData()
            data[SecureStoreKey.kExpiresIn.rawValue] = newValue
            setSecureStoreData(data: data)
        }
    }
    
    var isLoggedIn: (Bool, String?) {
        guard userAccessToken != nil,
              let loginTimeStamp = loginTimeStamp,
              let loginExpiresIn = loginExpiresIn else {
                  return (false, nil)
              }
        
        let loginTime = Date.dateFromString(dateString: loginTimeStamp, locale: nil)
        let timeNow = Date()
        
        let elapsedTime = timeNow.timeIntervalSince(loginTime)
        let seconds = floor(elapsedTime)
        
        if (seconds < loginExpiresIn) {
            return (true, nil)
        }
        
        return (false, "data.timeout".localized)
    }
    
    var isAccessTokenValid: Bool {
        return isLoggedIn.0
    }
    
    private var accessTokenData: [String: Any]?
    
    // MARK: - Credential and Schema Properties
    
    var userPackages = [Package]()
    var migratingPackages = [Package]()
    
    // MARK: - KeyPair Properties
    
    var userKeyPairs = [AsymmetricKeyPair]()
    var migratingKeyPairs = [AsymmetricKeyPair]()
    
    // MARK: - Contact Properties
    
    var userContacts = [Contact]()
    var migratingContacts = [Contact]()
    
    var contactUploadDetails = [ContactUploadDetails]()
    var migratingUploadDetails = [ContactUploadDetails]()
    
    // MARK:  Internal Methods
    
    mutating func extractLoginToken() {
        if let token = userAccessToken {
            accessTokenData = decode(jwtToken: token)
        } else {
            accessTokenData = nil
        }
    }
    
    mutating func loadUserData() {
        let data = getSecureStoreData()
        
        if let allPackages = data[SecureStoreKey.kPackages.rawValue] as? [[String: Any]] {
            let unsortedUserPackages = allPackages.map { Package(value: $0) }
            userPackages = unsortedUserPackages.sorted {
                $0.issuanceDateValue ?? Date() > $1.issuanceDateValue ?? Date()
            }
        }
        
        if let allKeyPairs = data[SecureStoreKey.kKeyPair.rawValue] as? [[String: Any]] {
            let unsortedUserKeyPairs = allKeyPairs.map { AsymmetricKeyPair(value: $0) }
            userKeyPairs = unsortedUserKeyPairs.sorted {
                $0.timestampValue > $1.timestampValue
            }
        }
        
        if let allContacts = data[SecureStoreKey.kContact.rawValue] as? [[String: Any]] {
            let unsortedUserContacts = allContacts.map { Contact(value: $0) }
            userContacts = unsortedUserContacts.sorted {
                $0.profileCredential?.issuanceDateValue ?? Date() < $1.profileCredential?.issuanceDateValue ?? Date()
            }
        }
        
        if let allContactUploadDetails = data[SecureStoreKey.kContactUploadDetails.rawValue] as? [[String: Any]] {
            contactUploadDetails = allContactUploadDetails.map { ContactUploadDetails(value: $0) }
        }
    }
    
    mutating func loadMigratingData() {
        let data = getSecureStoreData()
        
        if let allPackagesDictionary = data[SecureStoreKey.kPackages.rawValue] as? [String: Any],
           let migratingPackagesDictionary = Array(allPackagesDictionary.values) as? [[[String: Any]]] {
            let migratingPackagesArray = Array(migratingPackagesDictionary.joined())
            migratingPackages = migratingPackagesArray.map { Package(value: $0) }
        }
        
        if let allKeyPairsDictionary = data[SecureStoreKey.kKeyPair.rawValue] as? [String: Any],
           let migratingKeyPairsDictionary = Array(allKeyPairsDictionary.values) as? [[[String: Any]]] {
            let migratingKeyPairsArray = Array(migratingKeyPairsDictionary.joined())
            migratingKeyPairs = migratingKeyPairsArray.map { AsymmetricKeyPair(value: $0) }
        }
        
        if let allContactsDictionary = data[SecureStoreKey.kContact.rawValue] as? [String: Any],
           let migratingContactsDictionary = Array(allContactsDictionary.values) as? [[[String: Any]]] {
            let migratingContactsArray = Array(migratingContactsDictionary.joined())
            migratingContacts = migratingContactsArray.map { Contact(value: $0) }
        }
        
        if let allContactUploadDetailsDictionary = data[SecureStoreKey.kContactUploadDetails.rawValue] as? [String: Any],
           let migratingContactUploadDetailsDictionary = Array(allContactUploadDetailsDictionary.values) as? [[[String: Any]]] {
            let migratingContactUploadArray = Array(migratingContactUploadDetailsDictionary.joined())
            migratingUploadDetails = migratingContactUploadArray.map { ContactUploadDetails(value: $0) }
        }
    }
    
    mutating func resetDeepLinking() {
        deepLinkAction = nil
        deepLinkQueries = nil
        importURL = nil
    }
    
    mutating func resetUserLogin() {
        userAccessToken = nil
        loginTimeStamp = nil
        loginExpiresIn = nil
        
        didLoadHomeController = false
    }
    
    func performMigration() {
        DataStore.shared.loadMigratingData()
        
        let migratingPackages = DataStore.shared.migratingPackages
        DataStore.shared.migratePackages(migratingPackages)
        
        let migratingKeyPairs = DataStore.shared.migratingKeyPairs
        DataStore.shared.migrateKeyPair(migratingKeyPairs)
        
        let migratingContacts = DataStore.shared.migratingContacts
        DataStore.shared.migrateContact(migratingContacts)
        
        let migratingUploadDetails = DataStore.shared.migratingUploadDetails
        DataStore.shared.migrateContactUploadDetails(migratingUploadDetails)
        
        DataStore.shared.loadUserData()
    }
    
    func importKeychainArchive(url: URL, with password: String, completion: ((Result<Bool>) -> Void)) {
        BufferCompression().decompress(from: url, with: password) { json, errorMessage in
            guard let keychainDictionary = json else {
                completion(.success(false))
                return
            }
            
            do {
                try SecureStore.saveData(data: keychainDictionary, forUserAccount: SecureStoreKey.kAccount.rawValue, inService: SecureStoreKey.kAccount.rawValue)
                completion(.success(true))
            } catch {
                completion(.success(false))
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func decode(jwtToken jwt: String) -> [String: Any] {
        let segments = jwt.components(separatedBy: ".")
        return decodeJWTPart(segments[1]) ?? [:]
    }
    
    private func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 = base64 + padding
        }
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
    
    private func decodeJWTPart(_ value: String) -> [String: Any]? {
        guard let bodyData = base64UrlDecode(value),
              let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
                  return nil
              }
        
        return payload
    }
}

