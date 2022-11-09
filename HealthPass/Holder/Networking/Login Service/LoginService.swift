//
//  LoginService.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire

extension NSError {
    
    //Credential Expiry
    static let noVerifierCredential = NSError(domain: "No Verifier Credential", code: 5401,
                                           userInfo: [NSLocalizedDescriptionKey: "verification.credentialExpired".localized])
    
}

final class LoginService: Network {
    
    struct LoginBody: Codable {
        var email: String
        var password: String
        
        init(email: String, password: String) {
            self.email = email
            self.password = password
        }
    }
    
    private func performLoginRequest(email: String, password: String) -> DataRequest? {
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.healthPass)
        url.appendPathComponent(Network.users)
        url.appendPathComponent("login")
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = httpHeaders
        
        let httpBody = LoginBody(email: email, password: password)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        
        request.httpBody = try? encoder.encode(httpBody)
        
        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    /// Network layer call which would execute user login for the provided credentials
    ///
    /// - parameter email: String object which would accept the email
    ///
    /// - parameter password: String object which would accept the password
    ///
    /// - parameter completion: A closure of type JSON dictionary to be executed once the request has finished.
    ///
    @discardableResult
    public func performLogin(email: String, password: String,
                             completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        guard let dataRequest = LoginService().performLoginRequest(email: email, password: password) else {
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    print("[FAIL] - Perform Login - Server response failed : Invaild response data")
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        print("[FAIL] - Perform Login - Invalid Server response format")
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                       let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Login"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - Perform Login - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    print(String(format: "[RESPONSE] - Perform Login: %@", result))
                    completion?(.success(result))
                    return
                } catch {
                    print("[FAIL] - Perform Login - Server response failed : \(error.localizedDescription)")
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                print("[FAIL] - Perform Login - Server response failed : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }
    
    public func refreshLogin(completionHandler: CompletionHandler? = nil)  {
        
        let isLoggedIn = DataStore.shared.isLoggedIn.0
        if isLoggedIn {
            completionHandler?(.success(nil))
            return
        }
        
        #if HOLDER
        
        let emailString = "tester@poc.com"
        let passwordString = "testing123"
        LoginService().performLogin(email: emailString, password: passwordString) { result in
            
            self.loginResponseHandler(emailString: emailString,
                                      credential: nil,
                                      result: result,
                                      completionHandler: completionHandler)
            
        }
        
        #else
        
        if let credential = DataStore.shared.currentOrganization?.credential?.base64String {
            LoginService().performLogin(with: credential) { result in
                
                self.loginResponseHandler(emailString: nil,
                                          credential: credential,
                                          result: result,
                                          completionHandler: completionHandler)
                
            }
        } else {
            completionHandler?(.failure(NSError.noVerifierCredential))
        }
        
        #endif
    }
    
    private func loginResponseHandler(emailString: String? = nil,
                                      credential: String? = nil,
                                      result: Result<[String : Any]>,
                                      completionHandler: CompletionHandler? = nil) {
        switch result {
        case let .success(json):
            print(" [RESPONSE] - Perform Login : \(json)")
            
            if let accessToken = json["access_token"] as? String {
                DataStore.shared.userAccessToken = accessToken
                
                DataStore.shared.loginTimeStamp = Date.stringForDate(date: Date(), locale: nil)
                DataStore.shared.loginExpiresIn = json["expires_in"] as? Double
                
                completionHandler?(.success(nil))
            } else {
                let formatError = NSError.invalidDataResponseError
                print(" [FAIL] - Perform Login - Server response failed : \(formatError.localizedDescription)")
                DataStore.shared.resetUserLogin()
                
                completionHandler?(.failure(NSError.invalidDataResponseError))
            }
            
        case let .failure(error):
            print(" [FAIL] - Perform Login - Server response failed : \(error.localizedDescription)")
            DataStore.shared.resetUserLogin()
            
            completionHandler?(.failure(error))
        }
        
    }
}
