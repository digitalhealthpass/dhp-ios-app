//
//  DataSubmissionService.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire

class DataSubmissionService: Network {
    
    private func getSubmitDataRequest(at organization: String, publicKey: String?, documentId: String, linkId: String) -> DataRequest? {
        
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.dataSubmission)
        url.appendPathComponent(Network.data)
        url.appendPathComponent(Network.submit)

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = httpHeaders

        // TODO: MAKE A CONST
        let httpBodyDictionary = ["organization": organization,
                                  "publicKeyType": "pkcs1",
                                  "publicKey": publicKey,
                                  "documentId": documentId,
                                  "link": linkId]
        
        let httpBodyData = try? JSONSerialization.data(withJSONObject: httpBodyDictionary, options: .prettyPrinted)
        request.httpBody = httpBodyData
        
        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    @discardableResult
    public func submitData(at organization: String, publicKey: String?, documentId: String, linkId: String, completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        #if HOLDER
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.submitData(at: organization, publicKey: publicKey, documentId: documentId, linkId: linkId, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        #endif

        guard let dataRequest = DataSubmissionService().getSubmitDataRequest(at: organization, publicKey: publicKey, documentId: documentId, linkId: linkId) else {
            print("[FAIL] - Submit Data - Server response failed : Invaild data request")
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    print("[FAIL] - Submit Data - Server response failed : Invaild response data")
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        print("[FAIL] - Submit Data - Invalid Server response format")
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                       let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Data Submission"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - Submit Data - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    print(String(format: "[RESPONSE] - Submit Data: %@", result))
                    completion?(.success(result))
                    return
                } catch {
                    print("[FAIL] - Submit Data - Server response failed : \(error.localizedDescription)")
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                print("[FAIL] - Submit Data - Server response failed : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }
    
}
