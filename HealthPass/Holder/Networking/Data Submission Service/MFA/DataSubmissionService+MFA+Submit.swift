//
//  DataSubmissionService+MFA+Submit.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire

extension DataSubmissionService {
    
    private func submitMFARequest(for organization: String, with regCode: String, publicKey: String?) -> DataRequest? {
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.dataSubmission)
        url.appendPathComponent(Network.onboarding)
        url.appendPathComponent(Network.mfa)
        url.appendPathComponent(Network.submitregistration)
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = httpHeaders
        
        let httpBodyDictionary = ["organization": organization,
                                  "registrationCode": regCode,
                                  "publicKey": publicKey]
        
        let httpBodyData = try? JSONSerialization.data(withJSONObject: httpBodyDictionary, options: .prettyPrinted)
        request.httpBody = httpBodyData
        
        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    @discardableResult
    public func submitMFA(for organization: String, with regCode: String, completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
#if HOLDER
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.submitMFA(for: organization, with: regCode, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
#endif
        
        guard let generatedKeyPair = generateNewKeyPair(for: regCode), let publickey = updatePublic(for: generatedKeyPair) else {
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        guard let dataRequest = DataSubmissionService().submitMFARequest(for: organization, with: regCode, publicKey: publickey.base64EncodedString()) else {
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    print("[FAIL] - MFA Submit - Server response failed : Invaild response data")
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        print("[FAIL] - MFA Submit - Invalid Server response format")
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                       let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Data Submission"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - MFA Submit - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    if let keyPairDictionary = self.constructDictionary(generatedKeyPair: generatedKeyPair) {
                        self.saveKeyPair(dictionary: keyPairDictionary)
                    }
                    
                    print(String(format: "[RESPONSE] - MFA Submit: %@", result))
                    completion?(.success(result))
                    return
                } catch {
                    print("[FAIL] - MFA Submit - Server response failed : \(error.localizedDescription)")
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                print("[FAIL] - MFA Submit - Server response failed : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }
    
}

extension DataSubmissionService {
    
    private func generateNewKeyPair(for registrationCode: String) -> [String : Any]? {
        if let keyTuple = try? KeyGen.generateNewKeys(tag: registrationCode),
           let publickey = keyTuple.publickey, let privatekey = keyTuple.privatekey {
            
            let generatedKeyPair: [String : Any] = [
                "publickey": publickey,
                "privatekey": privatekey,
                "tag": registrationCode,
                "timestamp" : Date()
            ]
            
            return generatedKeyPair
        }
        
        return nil
    }
    
    private func updateTag(for dictionary: [String : Any?]) -> String? {
        return dictionary["tag"] as? String
    }
    
    private func updateTimestamp(for dictionary: [String : Any?]) -> Date? {
        return dictionary["timestamp"] as? Date
    }
    
    private func updatePublic(for dictionary: [String : Any?]) -> Data? {
        if let publickey = dictionary["publickey"] {
            let publickeySec = publickey as! SecKey
            return try? KeyGen.decodeKeyToData(publickeySec)
        }
        
        return nil
    }
    
    private func updatePrivate(for dictionary: [String : Any?]) -> Data? {
        if let privatekey = dictionary["privatekey"] {
            let privatekeySec = privatekey as! SecKey
            return try? KeyGen.decodeKeyToData(privatekeySec)
        }
        
        return nil
    }
    
    private func constructDictionary(generatedKeyPair: [String : Any]) -> [String: Any]? {
        var dictionary = [String: Any]()
        var id = String()
        
        if let tag = updateTag(for: generatedKeyPair) {
            dictionary["tag"] = tag
            id = String(format: "%@.%@", id, tag)
        }
        
        if let date = updateTimestamp(for: generatedKeyPair) {
            dictionary["timestamp"] = Date.stringForDate(date: date, dateFormatPattern: .keyGenFormat)
            id = String(format: "%@.%@", id, Date.stringForDate(date: date, dateFormatPattern: .timestampFormat))
        }
        
        if let publickey = updatePublic(for: generatedKeyPair) {
            dictionary["publickey"] = publickey.base64EncodedString()
        }
        
        if let privatekey = updatePrivate(for: generatedKeyPair) {
            dictionary["privatekey"] = privatekey.base64EncodedString()
        }
        
        dictionary["id"] = id
        
        return dictionary
    }
    
    private func saveKeyPair(dictionary: [String : Any]) {
        DataStore.shared.saveKeyPair(dictionary) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                DataStore.shared.loadUserData()
                NotificationCenter.default.post(name: ProfileTableViewController.RefreshKeychainIdentifier, object: nil)
            }
        }
    }
    
}
