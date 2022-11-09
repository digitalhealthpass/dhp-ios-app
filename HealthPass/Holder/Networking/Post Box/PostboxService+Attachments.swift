//
//  PostboxAllFilesForOrgService.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire
import os.log

extension PostboxService {
    
    private func getAllFilesRequest(for linkId: String, with passcode: String) -> DataRequest? {
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
       
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.postbox)
        url.appendPathComponent(Network.links)
        url.appendPathComponent(linkId)
        url.appendPathComponent(Network.attachments)
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        
        var headerFields = httpHeaders
        headerFields["x-postbox-access-token"] = passcode
        request.allHTTPHeaderFields = headerFields
        
        let dataRequest = Network.sharedManager.request(request)
        return dataRequest
    }
    
    @discardableResult
    public func getAllFiles(for linkId: String, with passcode: String, completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.getAllFiles(for: linkId, with: passcode, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        
        guard let dataRequest = PostboxService().getAllFilesRequest(for: linkId, with: passcode) else {
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    os_log("[FAIL] - Get All Files - Server response failed : Invaild response data", log: OSLog.services, type: .error)
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        os_log("[FAIL] - Get All Files - Invalid Server response format", log: OSLog.services, type: .error)
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                       let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("POBox"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        os_log("[FAIL] - Get All Files - Server response failed : %{private}@", log: OSLog.services, type: .error, error.localizedDescription)
                        completion?(.failure(error))
                        return
                    }
                    
                    os_log("[RESPONSE] - Get All Files: %{private}@", log: OSLog.services, type: .info, result)
                    completion?(.success(result))
                    return
                } catch {
                    os_log("[FAIL] - Get All Files - Server response failed : %{private}@", log: OSLog.services, type: .error, error.localizedDescription)
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                os_log("[FAIL] - Get All Files - Server response failed : %{private}@", log: OSLog.services, type: .error, error.localizedDescription)
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }
}
