//
//  DataSubmissionService+ConsentRevoke.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire
import os.log

extension OSLog {
    static let consentRevoke = OSLog(subsystem: subsystem, category: "consentRevoke")
}

extension DataSubmissionService {
    
    private func getConsentRevokeRequest(for orgId: String,  publickey: String) -> DataRequest? {
        
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.dataSubmission)
        url.appendPathComponent(Network.organization)
        url.appendPathComponent(orgId)
        url.appendPathComponent(Network.consentRevoke)
        // get url encoded publickey
        url.appendPathComponent(publickey.base64Encoded() ?? "")
        print("GET CONSENT REVOKE URL", url)
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.allHTTPHeaderFields = httpHeaders

        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    @discardableResult
    public func getConsentRevoke(for orgId: String, publickey: String, completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.getConsentRevoke(for: orgId, publickey: publickey, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        
        guard let dataRequest = DataSubmissionService().getConsentRevokeRequest(for: orgId, publickey: publickey) else {
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    os_log("[FAIL] - Consent Revoke - Server response failed : Invaild response data", log: OSLog.consentRevoke, type: .error)
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        os_log("[FAIL] - Consent Revoke - Invalid Server response format", log: OSLog.consentRevoke, type: .error)
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                       let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Data Submission"),
                                            code: 200,
                                            userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        os_log("[FAIL] - Consent Revoke - Server response failed : %@", log: OSLog.consentRevoke, type: .error, error.localizedDescription)
                        completion?(.failure(error))
                        return
                    }
                    
                    os_log("[RESPONSE] - Consent Revoke -Register: %@", log: OSLog.consentRevoke, type: .error, result)
                    completion?(.success(result))
                    return
                } catch {
                    os_log("[FAIL] - Consent Revoke - Server response failed : %@", log: OSLog.consentRevoke, type: .error, error.localizedDescription)
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                os_log("[FAIL] - Consent Revoke - Server response failed : %@", log: OSLog.consentRevoke, type: .error, error.localizedDescription)
                completion?(.failure(error))
            }
        }
        return dataRequest
    }
}
