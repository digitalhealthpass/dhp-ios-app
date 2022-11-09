//
//  IssuerService+Metadata.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire

extension IssuerService {
    
    private func getIssuerRequestMetadata(for issuerId: String) -> DataRequest? {
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.healthPass)
        url.appendPathComponent(Network.issuers)
        url.appendPathComponent(issuerId)
        url.appendPathComponent("metadata")

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        
        var headerFields = httpHeaders
        headerFields["did"] = issuerId
        
        request.allHTTPHeaderFields = headerFields
        
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
    public func getIssuerMetadata(issuerId: String,
                          completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.getIssuerMetadata(issuerId: issuerId, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }

        guard let dataRequest = IssuerService().getIssuerRequestMetadata(for: issuerId) else {
            print("[FAIL] - Get Issuers Metadata - Server response failed : Invaild data request")
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    print("[FAIL] - Get Issuers Metadata - Server response failed : Invaild response data")
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        print("[FAIL] - Get Issuers Metadata - Invalid Server response format")
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                        let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Issuer"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - Get Issuers Metadata - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    print(String(format: "[RESPONSE] - Get Issuers Metadata: %@", result))
                    completion?(.success(result))
                    return
                } catch {
                    print("[FAIL] - Get Issuers Metadata - Server response failed : \(error.localizedDescription)")
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                print("[FAIL] - Get Issuers Metadata - Server response failed : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }

}
