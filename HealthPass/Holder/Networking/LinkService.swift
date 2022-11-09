//
//  LinkService.swift
//  Holder
//
//  Created by Gautham Velappan on 10/13/20.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire

class PostboxLinkService: Network {

    private func createLinkRequest(for password: String? = nil, singleuse: Bool? = nil) -> DataRequest? {
        let urlString = Network.baseURL + Network.postboxLinks

        guard let urlComponents = URLComponents(string: urlString) else { return nil }
        guard let url = urlComponents.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        
        var headerFields = httpHeaders
        headerFields["x-hpass-issuer-id"] = Network.issuerId

        request.allHTTPHeaderFields = headerFields
        
        request.setValue("Bearer \(DataStore.shared.userAccessToken!)", forHTTPHeaderField: "Authorization")
        
        var httpBodyDictionary = [String: Any]()
        if let password = password {
            httpBodyDictionary = [ "password": password ]
        }
        if let singleuse = singleuse {
            httpBodyDictionary = [ "multiple": (!singleuse).description ]
        }
        
        if !httpBodyDictionary.isEmpty {
            let httpBodyData = try? JSONSerialization.data(withJSONObject: httpBodyDictionary, options: .prettyPrinted)
            request.httpBody = httpBodyData
        }

        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest

    }
    
    /// Network layer call to create link to start publishing credentials
    ///
    /// - parameter password: custom password for the genereted link
    ///
    /// - parameter singleuse: indicates if the link is for single use
    ///
    /// - parameter completion: A closure of type JSON dictionary to be executed once the request has finished.
    ///
    @discardableResult
    public func createLink(for password: String? = nil, singleuse: Bool? = nil,
                          completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        guard let dataRequest = PostboxLinkService().createLinkRequest(for: password, singleuse: singleuse) else {
            print("[FAIL] - Create Link - Server response failed : Invaild data request")
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    print("[FAIL] - Create Link - Server response failed : Invaild response data")
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        print("[FAIL] - Create Link - Invalid Server response format")
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                        let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Client Error"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - Create Link - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    print(String(format: "[RESPONSE] - Create Link: %@", result))
                    completion?(.success(result))
                    return
                } catch {
                    print("[FAIL] - Create Link - Server response failed : \(error.localizedDescription)")
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                print("[FAIL] - Create Link - Server response failed : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }
}
