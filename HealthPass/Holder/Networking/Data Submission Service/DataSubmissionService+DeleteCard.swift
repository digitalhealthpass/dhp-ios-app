//
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
    static let services = OSLog(subsystem: subsystem, category: "services")
}

extension DataSubmissionService {
    
    private func offBoardContactRequest(for orgId: String, contactId: String,
                                        linkId: String? = nil, publickey: String? = nil, documentId: String? = nil, signedConsentReceipt: [String: Any]? = nil) -> DataRequest? {
        
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.dataSubmission)
        url.appendPathComponent(Network.onboarding)
        url.appendPathComponent(orgId)
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.delete.rawValue
        
        //Off board with revoke
        if let signedConsentReceipt = signedConsentReceipt {
            request.httpBody = try? JSONSerialization.data(withJSONObject: signedConsentReceipt, options: .prettyPrinted)
        }
        
        var defaultHeaders = httpHeaders
        defaultHeaders["x-hpass-datasubmission-key"] = contactId
        
        //Off board with revoke
        if let publickey = publickey {
            defaultHeaders["x-hpass-datasubmission-key"] = publickey
        }
        
        if let linkId = linkId {
            defaultHeaders["x-hpass-link-id"] = linkId
        }
        
        if let documentId = documentId {
            defaultHeaders["x-hpass-key-type"] = Network.publicKeyType
            defaultHeaders["x-hpass-document-id"] = documentId
        }
        
        
        request.allHTTPHeaderFields = defaultHeaders
        
        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    @discardableResult
    public func offBoardContact(for orgId: String, contactId: String,
                                linkId: String? = nil, publickey: String? = nil, documentId: String? = nil, signedConsentReceipt: [String: Any]? = nil,
                                completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.offBoardContact(for: orgId, contactId: contactId, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        
        guard let dataRequest = DataSubmissionService().offBoardContactRequest(for: orgId, contactId: contactId,
                                                                                  linkId: linkId,
                                                                               publickey: publickey, documentId: documentId,
                                                                               signedConsentReceipt: signedConsentReceipt) else {
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    os_log("[FAIL] - Off-board Contact - Server response failed : Invaild response data", log: OSLog.services, type: .error)
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        os_log("[FAIL] - Off-board Contact - Invalid Server response format", log: OSLog.services, type: .error)
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                       let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Data Submission"),
                                            code: 200,
                                            userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        os_log("[FAIL] - Off-board Contact - Server response failed : %@", log: OSLog.services, type: .error, error.localizedDescription)
                        completion?(.failure(error))
                        return
                    }
                    
                    os_log("[RESPONSE] - Off-board Contact -Register: %@", log: OSLog.services, type: .error, result)
                    completion?(.success(result))
                    return
                } catch {
                    os_log("[FAIL] - Off-board Contact - Server response failed : %@", log: OSLog.services, type: .error, error.localizedDescription)
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                os_log("[FAIL] - Off-board Contact - Server response failed : %@", log: OSLog.services, type: .error, error.localizedDescription)
                completion?(.failure(error))
            } 
        }
        
        return dataRequest
    }
}
