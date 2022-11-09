//
//  CosAllFilesForHolderService.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire
import os.log

extension DataSubmissionService {
    ///cos/{holderId}
    ////cos/{orgId}/owner/{holderId}
    private func getCOSFilesRequest(for orgID: String, and holderID: String, with signature: String) -> DataRequest? {
        
        let signatureEncodeSlash = signature.replacingOccurrences(of: "/", with: "%2F")
        let signatureEncodePlus = signatureEncodeSlash.replacingOccurrences(of: "+", with: "%2B")
        
        guard var urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        urlComponents.queryItems = [
            URLQueryItem(name: "publicKeyType", value: "pkcs1"),
            URLQueryItem(name: "signatureValue", value: signatureEncodePlus),
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard var url = urlComponents.url else { return nil }
        let encodedHolderID = holderID.replacingOccurrences(of: "/", with: "%2F")
        let encodedHolderIDWithPlus = encodedHolderID.replacingOccurrences(of: "+", with: "%2B")
        
        url.appendPathComponent(Network.dataSubmission)
        url.appendPathComponent(Network.cos)
        url.appendPathComponent(orgID)
        url.appendPathComponent(Network.owner)
        
        guard let urlStringWithPath = url.appendingPathComponent(encodedHolderIDWithPlus).absoluteString.removingPercentEncoding else { return nil }
        guard let requiredURL = URL(string: urlStringWithPath) else { return nil }
        
        var request = URLRequest(url: requiredURL)
        request.httpMethod = HTTPMethod.get.rawValue
        
        let headerFields = httpHeaders
        request.allHTTPHeaderFields = headerFields
        
        let dataRequest = Network.sharedManager.request(request)
        return dataRequest
    }
    
    @discardableResult
    public func getCOSFiles(for orgID: String, and holderID: String, with signature: String, completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.getCOSFiles(for: orgID, and: holderID, with: signature, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        
        guard let dataRequest = DataSubmissionService().getCOSFilesRequest(for: orgID, and: holderID, with: signature) else {
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    os_log("[FAIL] - Get Cos Files for Holder - Server response failed : Invaild response data", log: OSLog.services, type: .error)
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        os_log("[FAIL] - Get Cos Files for Holder - Invalid Server response format", log: OSLog.services, type: .error)
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                       let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Data Submission"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        os_log("[FAIL] - Get Cos Files for Holder - Server response failed : %{private}@", log: OSLog.services, type: .error, error.localizedDescription)
                        completion?(.failure(error))
                        return
                    }
                    os_log("[RESPONSE] - Get Cos Files for Holder: %{private}@", log: OSLog.services, type: .info, result)
                    completion?(.success(result))
                    return
                } catch {
                    os_log("[FAIL] - Get Cos Files for Holder - Server response failed : %{private}@", log: OSLog.services, type: .error, error.localizedDescription)
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                os_log("[FAIL] - Get Cos Files for Holder - Server response failed : %{private}@", log: OSLog.services, type: .error, error.localizedDescription)
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }
}
