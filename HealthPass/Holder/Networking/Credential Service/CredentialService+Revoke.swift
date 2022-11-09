//
//  CredentialService+Revoke.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire

struct RevokeBody: Codable {
    var credentialID: String
    var reason: String
    
    init(did: String, reason: String) {
        self.credentialID = did
        self.reason = reason
    }
}

extension CredentialService {
    
    private func getRevokeStatusRequest(for did: String) -> DataRequest? {
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.healthPass)
        url.appendPathComponent(Network.credentials)
        url.appendPathComponent(did)
        url.appendPathComponent("revoke_status")
        url.appendPathComponent("optional")
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        
        var headerFields = httpHeaders
        headerFields["credentialID"] = did
        
        request.allHTTPHeaderFields = headerFields
        
        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    /// Network layer call to get revoke status of a credential
    ///
    /// - parameter did: credential's unique identifier
    ///
    /// - parameter completion: A closure of type JSON dictionary to be executed once the request has finished.
    ///
    @discardableResult
    public func getRevokeStatus(for did: String,
                                completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.getRevokeStatus(for: did, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        
        guard let dataRequest = CredentialService().getRevokeStatusRequest(for: did) else {
            print("[FAIL] - Get Revoke Status - Server response failed : Invaild data request")
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    print("[FAIL] - Get Revoke Status - Server response failed : Invaild response data")
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        print("[FAIL] - Get Revoke Status - Invalid Server response format")
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                        let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Credential"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - Revoke Credential - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    print(String(format: "[RESPONSE] - Get Revoke Status: %@", result))
                    completion?(.success(result))
                    return
                } catch {
                    print("[FAIL] - Get Revoke Status - Server response failed : \(error.localizedDescription)")
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                print("[FAIL] - Get Revoke Status - Server response failed : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }
    
    // ----
    private func revokeCredentialRequest(for did: String, with reason: String) -> DataRequest? {
        let urlString = Network.baseURL + Network.credentials
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = httpHeaders

        let httpBody = RevokeBody(did: did, reason: reason)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        
        request.httpBody = try? encoder.encode(httpBody)

        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    /// Network layer call to  revoke a given credential
    ///
    /// - parameter did: credential's unique identifier
    ///
    /// - parameter completion: A closure of type JSON dictionary to be executed once the request has finished.
    ///
    @discardableResult
    public func revokeCredential(for did: String, with reason: String,
                                 completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        guard let dataRequest = CredentialService().revokeCredentialRequest(for: did, with: reason) else {
            print("[FAIL] - Revoke Credential - Server response failed : Invaild data request")
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    print("[FAIL] - Revoke Credential - Server response failed : Invaild response data")
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        print("[FAIL] - Revoke Credential - Invalid Server response format")
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                        let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Credential"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - Revoke Credential - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    print(String(format: "[RESPONSE] - Revoke Credential: %@", result))
                    completion?(.success(result))
                    return
                } catch {
                    print("[FAIL] - Revoke Credential - Server response failed : \(error.localizedDescription)")
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                print("[FAIL] - Revoke Credential - Server response failed : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }
    
}
