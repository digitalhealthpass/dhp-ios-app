//
//  IssuerService + Issuer.swift
//  Holder
//
//  Created by Yevtushenko Valeriia on 06.12.2021.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire
import VerifiableCredential

//Public Key for IDHP, GHP and VC
extension IssuerService {
    
    private func getIssuerRequest(for issuerId: String? = nil) -> DataRequest? {
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.healthPass)
        url.appendPathComponent(Network.issuers)
        
        var headerFields = httpHeaders
        
        if let issuerId = issuerId {
            url.appendPathComponent(issuerId)
            headerFields["did"] = issuerId
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        
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
    public func getIssuer(issuerId: String? = nil,
                          completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.getIssuer(issuerId: issuerId, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        
        guard let dataRequest = IssuerService().getIssuerRequest(for: issuerId) else {
            print("[FAIL] - Get Issuers Info - Server response failed : Invaild data request")
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    print("[FAIL] - Get Issuers Info - Server response failed : Invaild response data")
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        print("[FAIL] - Get Issuers Info - Invalid Server response format")
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                       let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Issuer"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - Get Issuers Info - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    print(String(format: "[RESPONSE] - Get Issuers Info: %@", result))
                    completion?(.success(result))
                    return
                } catch {
                    print("[FAIL] - Get Issuers Info - Server response failed : \(error.localizedDescription)")
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                print("[FAIL] - Get Issuers Info - Server response failed : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }
    
}

//Public Key for SCH and DCC
extension IssuerService {
    
    private func getGenericIssuerRequest(issuerId: String?, bookmark: String?, pagesize: Int?, type: VCType) -> DataRequest? {
        guard var urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        
        urlComponents.queryItems = [ URLQueryItem(name: "pagesize", value: String(pagesize ?? IssuerService.min_page_size)),
                                     URLQueryItem(name: "bookmark", value: bookmark) ]
        
        if type == .DCC, let kid = issuerId {
            urlComponents.queryItems = [ URLQueryItem(name: "kid", value: kid),
                                         URLQueryItem(name: "pagesize", value: String(IssuerService.min_page_size)),
                                         URLQueryItem(name: "bookmark", value: bookmark) ]
        }
        
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.healthPass)
        url.appendPathComponent(Network.genericIssuers)
        if type == .SHC {
            url.appendPathComponent("vci")
            
            if (issuerId != nil) {
                url.appendPathComponent("query")
            }
        } else if type == .DCC {
            url.appendPathComponent("dcc")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.allHTTPHeaderFields = httpHeaders
        
        if type == .SHC, let iss = issuerId {
            let httpBodyDictionary = [ "url": iss ]
            let httpBody = try? JSONSerialization.data(withJSONObject: httpBodyDictionary, options: .prettyPrinted)
            request.httpBody = httpBody
          
            request.httpMethod = HTTPMethod.post.rawValue
        }
        
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
    public func getGenericIssuer(issuerId: String? = nil, bookmark: String? = nil, pagesize: Int? = nil, type: VCType,
                                 completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.getGenericIssuer(issuerId: issuerId, bookmark: bookmark, pagesize: pagesize, type: type, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        
        guard let dataRequest = IssuerService().getGenericIssuerRequest(issuerId: issuerId, bookmark: bookmark, pagesize: pagesize, type: type) else {
            print("[FAIL] - Get Generic Issuers Info - Server response failed : Invaild data request")
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    print("[FAIL] - Get Generic Issuers Info - Server response failed : Invaild response data")
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        print("[FAIL] - Get Generic Issuers Info - Invalid Server response format")
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                       let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Issuer"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - Get Generic Issuers Info - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    print(String(format: "[RESPONSE] - Get Generic Issuers Info: %@", result))
                    completion?(.success(result))
                    return
                } catch {
                    print("[FAIL] - Get Generic Issuers Info - Server response failed : \(error.localizedDescription)")
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                print("[FAIL] - Get Generic Issuers Info - Server response failed : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }
    
}
