//
//  verifierConfigurationServices.swift
//  Verifier
//
//  Created by Gautham Velappan on 8/13/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire

class VerifierConfigurationServices: Network {
    
    private func getVerifierConfigurationRequest(for configId: String, version: String?) -> DataRequest? {
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.verifier)
        url.appendPathComponent(Network.config)
        url.appendPathComponent(Network.verifierConfigurations)
        
        url.appendPathComponent(configId)
        url.appendPathComponent(version ?? "latest")
        
        url.appendPathComponent(Network.content)

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        
        request.allHTTPHeaderFields = httpHeaders
        
        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    /// Network layer call to get issuer name and credential name
    ///
    /// - parameter did: credential's unique identifier
    ///
    /// - parameter completion: A closure of type JSON dictionary to be executed once the request has finished.
    ///
    @discardableResult
    public func getVerifierConfiguration(for configId: String, version: String?,
                                         completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.getVerifierConfiguration(for: configId, version: version, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        
        guard let dataRequest = VerifierConfigurationServices().getVerifierConfigurationRequest(for: configId, version: version) else {
            print("[FAIL] - Get Verifier Configuration - Server response failed : Invaild data request")
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    print("[FAIL] - Get Verifier Configuration - Server response failed : Invaild response data")
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        print("[FAIL] - Get Verifier Configuration - Invalid Server response format")
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                       let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Config"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - Get Verifier Configuration - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    print(String(format: "[RESPONSE] - Get Verifier Configuration: %@", result))
                    completion?(.success(result))
                    return
                } catch {
                    print("[FAIL] - Get Verifier Configuration - Server response failed : \(error.localizedDescription)")
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                print("[FAIL] - Get Verifier Configuration - Server response failed : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }
    
}
