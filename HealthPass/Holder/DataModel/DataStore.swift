//
//  DataStore.swift
//  HealthPass
//
//  Created by Gautham Velappan on 6/23/20.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Locksmith
import Alamofire

enum LocksmithKey: String {
    case kAccount = "account.IBM.HealthPass"
    
    case kLoginTimeStamp = "loginTime"
    case kEmail = "email"
    case kPassword = "password"
    case kToken = "token"
    case kCredentials = "kCredentials"
    
}

struct DataStore {
    
    static var shared = DataStore()
    
    // MARK: Internal Properties
    
    var loginTimeStamp: String? {
        get {
            if let data = Locksmith.loadDataForUserAccount(userAccount: LocksmithKey.kAccount.rawValue) {
                let loginTimeStamp = data[LocksmithKey.kLoginTimeStamp.rawValue] as? String
                return loginTimeStamp
            }
            
            return nil
        } set {
            var data = Locksmith.loadDataForUserAccount(userAccount: LocksmithKey.kAccount.rawValue) ?? [String : Any]()
            data[LocksmithKey.kLoginTimeStamp.rawValue] = newValue
            do {
                try Locksmith.saveData(data: data, forUserAccount: LocksmithKey.kAccount.rawValue)
            } catch LocksmithError.duplicate {
                try? Locksmith.updateData(data: data, forUserAccount: LocksmithKey.kAccount.rawValue)
            } catch {
                print(error)
            }
        }
    }
    
    var userEmail: String? {
        get {
            if let data = Locksmith.loadDataForUserAccount(userAccount: LocksmithKey.kAccount.rawValue) {
                let userEmail = data[LocksmithKey.kEmail.rawValue] as? String
                return userEmail
            }
            
            return nil
        } set {
            var data = Locksmith.loadDataForUserAccount(userAccount: LocksmithKey.kAccount.rawValue) ?? [String : Any]()
            data[LocksmithKey.kEmail.rawValue] = newValue
            do {
                try Locksmith.saveData(data: data, forUserAccount: LocksmithKey.kAccount.rawValue)
            } catch LocksmithError.duplicate {
                try? Locksmith.updateData(data: data, forUserAccount: LocksmithKey.kAccount.rawValue)
            } catch {
                print(error)
            }
        }
    }
    
    var userToken: String? {
        get {
            if let data = Locksmith.loadDataForUserAccount(userAccount: LocksmithKey.kAccount.rawValue) {
                let userToken = data[LocksmithKey.kToken.rawValue] as? String
                return userToken
            }
            
            return nil
        } set {
            var data = Locksmith.loadDataForUserAccount(userAccount: LocksmithKey.kAccount.rawValue) ?? [String : Any]()
            data[LocksmithKey.kToken.rawValue] = newValue
            do {
                try Locksmith.saveData(data: data, forUserAccount: LocksmithKey.kAccount.rawValue)
            } catch LocksmithError.duplicate {
                try? Locksmith.updateData(data: data, forUserAccount: LocksmithKey.kAccount.rawValue)
            } catch {
                print(error)
            }
        }
    }
    
    var isLoggedIn: Bool {
        guard userEmail != nil, userToken != nil, let loginTimeStamp = DataStore.shared.loginTimeStamp else {
            return false
        }
        
        let loginTime = Date.dateFromString(dateString: loginTimeStamp)
        let timeNow = Date()
        
        let elapsedTime = timeNow.timeIntervalSince(loginTime)
        let hours = floor(elapsedTime/60/60)
        
        return (hours < 12)
    }
    
    var loginTokenData: [String: Any]?
    
    private var userCredentialsData = [[String: Any]]()
    
    var userCredentials: [Credential]! {
        get {
            let userCredentials = userCredentialsData.map { Credential(value: $0)}
            return userCredentials
        }
    }
    
    // MARK: Internal Methods
    
    mutating func extractLoginToken() {
        guard let token = self.userToken else {
            self.loginTokenData = nil
            return
        }
        
        loginTokenData = decode(jwtToken: token)
    }
    
    mutating func loadUserCredentials() {
        userCredentialsData.removeAll()
        guard let email = userEmail else {
            return
        }
        
        if let data = Locksmith.loadDataForUserAccount(userAccount: LocksmithKey.kAccount.rawValue) {
            if let allCredentials = data[LocksmithKey.kCredentials.rawValue] as? [String: Any] {
                if let userCredentials = allCredentials[email] as? [[String: Any]] {
                    self.userCredentialsData.append(contentsOf: userCredentials)
                }
            }
        }
    }
    
    mutating func saveCredential(_ credential: [String: Any], for user: String? = nil, completion: ((Result<Bool>) -> Void)? = nil) {
        guard let email = user ?? userEmail else {
            return
        }
        
        var data = Locksmith.loadDataForUserAccount(userAccount: LocksmithKey.kAccount.rawValue) ?? [String : Any]()
        var filteredUserCredentials = [[String : Any]]()
        
        if let allCredentials = data[LocksmithKey.kCredentials.rawValue] as? [String: Any] {
            let userCredentials = (allCredentials[email] as? [[String: Any]]) ?? [[String: Any]]()
            filteredUserCredentials = userCredentials.filter { ($0["id"] as? String) != (credential["id"] as? String) }
        }
        
        filteredUserCredentials.append(credential)
        
        data[LocksmithKey.kCredentials.rawValue] = [email: filteredUserCredentials]
        
        do {
            try Locksmith.updateData(data: data, forUserAccount: LocksmithKey.kAccount.rawValue)
            completion?(.success(true))
        } catch {
            completion?(.failure(error))
        }
    }
    
    mutating func eraseAllUserCredentials(_ credential: [String: Any], for user: String? = nil, completion: ((Result<Bool>) -> Void)? = nil) {
        guard let email = userEmail else {
            return
        }
        
        var data = Locksmith.loadDataForUserAccount(userAccount: LocksmithKey.kAccount.rawValue) ?? [String : Any]()
        data[LocksmithKey.kCredentials.rawValue] = [email: nil]
       
        do {
            try Locksmith.updateData(data: data, forUserAccount: LocksmithKey.kAccount.rawValue)
            completion?(.success(true))
        } catch {
            completion?(.failure(error))
        }
    }
    
    mutating func resetUserLogin() {
        loginTimeStamp = nil
        userEmail = nil
        userToken = nil
    }
    
    func resetKeychain() {
        try? Locksmith.deleteDataForUserAccount(userAccount: LocksmithKey.kAccount.rawValue)
    }
    
    // MARK: Private Methods
    
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
