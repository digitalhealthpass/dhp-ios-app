//
//  DataSubmissionService+Config.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire

extension DataSubmissionService {

    private func getRegistrationConfigRequest(for organization: String) -> DataRequest? {
        
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.dataSubmission)
        url.appendPathComponent(Network.organization)
        url.appendPathComponent(organization)
        url.appendPathComponent(Network.regconfig)

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.allHTTPHeaderFields = httpHeaders
        
        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    @discardableResult
    public func getRegistrationConfig(for organization: String, completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        #if HOLDER
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.getRegistrationConfig(for: organization, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        #endif

        guard let dataRequest = DataSubmissionService().getRegistrationConfigRequest(for: organization) else {
            print("[FAIL] - Registration Config - Server response failed : Invaild data request")
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    print("[FAIL] - Registration Config - Server response failed : Invaild response data")
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        print("[FAIL] - Registration Config - Invalid Server response format")
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                       let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Data Submission"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - Registration Config - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    print(String(format: "[RESPONSE] - Registration Config: %@", result))
                    completion?(.success(result))
                    return
                } catch {
                    print("[FAIL] - Registration Config - Server response failed : \(error.localizedDescription)")
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                print("[FAIL] - Registration Config - Server response failed : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }

}
