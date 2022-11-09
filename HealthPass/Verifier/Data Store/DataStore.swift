//
//  DataStore.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit
import Alamofire
import SecureStore
import VerificationEngine

enum SecureStoreKey: String {
    case kAccount = "IBM.Verifier"
    
    case kAccessToken = "accessToken"
    case kLoginTimeStamp = "loginTime"
    case kExpiresIn = "expires_in"
    
    case kPackages = "kPackages"
    case kKeyPair = "kKeyPair"
    
    case kUserID = "userid"
    case kPassword = "password"
    case kDOAuthentication = "DOAuthentication"
    
}

enum UserDefaultsKey: String {
    case kdidAcceptPrivacy = "IBM.UserDefaults.didAcceptPrivacy"
    case kdidTermsConditions = "IBM.UserDefaults.didTermsConditions"
    case kdidSelectDataCenter = "IBM.UserDefaults.didSelectDataCenter"
    case kdidGetStarted = "IBM.UserDefaults.didGetStarted"
    
    case kSchemaArray = "IBM.UserDefaults.schemaArray"
    case kIssuerArray = "IBM.UserDefaults.issuerArray"
    case kJWKSetArray = "IBM.UserDefaults.jwkSetArray"
    case kIssuerKeyArray = "IBM.UserDefaults.issuerKeyArray"
    case kIssuerMetadataArray = "IBM.UserDefaults.issuerMetadataArray"
    case kVerifierConfigurationArray = "IBM.UserDefaults.verifierConfigurationArray"

    case kOrganizationArray = "IBM.UserDefaults.organizationArray"
    case kCurrentOrganization = "IBM.UserDefaults.currentOrganization"
    
    case kMetricsArray = "IBM.UserDefaults.metricsArray"
    
    case kRevocationVerification = "IBM.UserDefaults.revocationVerification"
    
    case kKioskMode = "IBM.UserDefaults.kioskMode"
    case kFrontCamera = "IBM.UserDefaults.frontCamera"
    case kAlwaysDismiss = "IBM.UserDefaults.alwaysDismiss"
    case kDismissDuration = "IBM.UserDefaults.dismissDuration"
    
    case kSoundFeedback = "IBM.UserDefaults.soundFeedback"
    case kHapticFeedback = "IBM.UserDefaults.hapticFeedback"

}

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
    
    public func resetKeychain() {
        try? SecureStore.deleteDataForUserAccount(userAccount: SecureStoreKey.kAccount.rawValue, inService: SecureStoreKey.kAccount.rawValue)
    }
    
}

struct DataStore {
    
    static var shared = DataStore()
    
    // MARK: - Organization Properties
    
    var allOrganization: [Package]? {
        get {
            return allOrganizationDictionary?.compactMap { Package(value: $0) }
        }
    }
    
    var allOrganizationDictionary: [[String: Any]]? {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kOrganizationArray.rawValue)
        } get {
            return UserDefaults.standard.array(forKey: UserDefaultsKey.kOrganizationArray.rawValue) as? [[String: Any]]
        }
    }
    
    var currentOrganization: Package? {
        get {
            if let currentOrganizationDictionary = currentOrganizationDictionary {
                return Package(value: currentOrganizationDictionary)
            }
            
            return nil
        }
    }
    
    var currentOrganizationDictionary: [String: Any]? {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kCurrentOrganization.rawValue)
        } get {
            return UserDefaults.standard.value(forKey: UserDefaultsKey.kCurrentOrganization.rawValue) as? [String : Any]
        }
    }
    
    var currentVerifierConfiguration: VerifierConfiguration?
    
    // MARK: - Metrics Properties
    
    var allMetrics: [Metric]? {
        get {
            return allMetricsDictionary?.compactMap { Metric(value: $0) }
        }
    }
    
    var allMetricsDictionary: [[String: String]]? {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kMetricsArray.rawValue)
        } get {
            return UserDefaults.standard.array(forKey: UserDefaultsKey.kMetricsArray.rawValue) as? [[String: String]]
        }
    }
    
    // MARK: - App Properties
    
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
    
    var didSelectDataCenter: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kdidSelectDataCenter.rawValue)
        } get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKey.kdidSelectDataCenter.rawValue)
        }
    }
    
    var didGetStarted: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kdidGetStarted.rawValue)
        } get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKey.kdidGetStarted.rawValue)
        }
    }
    
    //Kiosk
    var kioskModeState: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kKioskMode.rawValue)
        } get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKey.kKioskMode.rawValue)
        }
    }

    var frontCameraState: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kFrontCamera.rawValue)
        } get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKey.kFrontCamera.rawValue)
        }
    }

    var alwaysDismissState: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kAlwaysDismiss.rawValue)
        } get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKey.kAlwaysDismiss.rawValue)
        }
    }

    var alwaysDismissDuration: Int {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kDismissDuration.rawValue)
        } get {
            return UserDefaults.standard.integer(forKey: UserDefaultsKey.kDismissDuration.rawValue)
        }
    }

    //Feedback
    var soundFeedbackState: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kSoundFeedback.rawValue)
        } get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKey.kSoundFeedback.rawValue)
        }
    }

    var hapticFeedbackState: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.kHapticFeedback.rawValue)
        } get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKey.kHapticFeedback.rawValue)
        }
    }

    // MARK: - Login Properties
    
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
        
        return (false, "Session Timed Out")
    }
    
    var isAccessTokenValid: Bool {
        return isLoggedIn.0
    }
    
    var testCredentialItems = [TestCredentialItem]()
        
    private var accessTokenData: [String: Any]?
    
    mutating func extractLoginToken() {
        if let token = userAccessToken {
            accessTokenData = decode(jwtToken: token)
        } else {
            accessTokenData = nil
        }
    }
    
    mutating func resetUserLogin() {
        currentOrganizationDictionary = nil
        currentVerifierConfiguration = nil
        
        userAccessToken = nil
        loginTimeStamp = nil
        loginExpiresIn = nil
    }
    
    public func resetCache() {
        DataStore.shared.deleteAllIssuers()
        DataStore.shared.deleteAllJWKSet()
        DataStore.shared.deleteAllIssuerKey()
        
        DataStore.shared.deleteAllSchemas()
        DataStore.shared.deleteAllIssuerMetadata()
        DataStore.shared.deleteAllVerifierConfiguration()
    }
    
    public func resetOrganizations() {
        DataStore.shared.deleteAllOrganizations()
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
