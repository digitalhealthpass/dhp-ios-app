//
//  PostboxDocumentService.swift
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
    static let networkService = OSLog(subsystem: subsystem, category: "networkService")
}

extension PostboxService {

    private func uploadDocumentsRequest(at url: String? = nil, form content: String, link: String, password: String, name: String) -> DataRequest? {
        let urlString = url ?? String(format: "%@/%@/%@", Network.baseURL, Network.postbox, Network.documents)
        guard let urlComponents = URLComponents(string: urlString) else { return nil }
        guard let url = urlComponents.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = httpHeaders
        
        let httpBodyDictionary = [ "content": content,
                                   "link": link,
                                   "password": password,
                                   "name": name ]
        let httpBodyData = try? JSONSerialization.data(withJSONObject: httpBodyDictionary, options: .prettyPrinted)
        request.httpBody = httpBodyData

        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    /// Network layer call to  publishing credentials
    ///
    /// - parameter credentials:
    ///
    /// - parameter link:
    ///
    /// - parameter password:
    ///
    /// - parameter name:
    ///
    /// - parameter completion: A closure of type JSON dictionary to be executed once the request has finished.
    ///
    @discardableResult
    public func uploadDocuments(at url: String? = nil, for content: String, link: String, password: String, name: String,
                          completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        #if HOLDER
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.uploadDocuments(at: url, for: content, link: link, password: password, name: name, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        #endif
        
        guard let dataRequest = PostboxService().uploadDocumentsRequest(at: url, form: content, link: link, password: password, name: name) else {
            os_log("[FAIL] - %{private}% - Server response failed : Invaild data request", log: OSLog.networkService, type: .error, String(describing:self))
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    os_log("[FAIL] - %{private}@ - Server response failed : Invaild response data", log: OSLog.networkService, type: .error, String(describing:self))
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any], let status = response.response?.statusCode else {
                        os_log("[FAIL] - %{private}@ - Invalid Server response format", log: OSLog.networkService, type: .error, String(describing:self))
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if (200...299).contains(status) {
                        os_log("[RESPONSE] - %{private}@ : %{private}@", log: OSLog.networkService, type: .info, String(describing:self), result)
                        completion?(.success(result))
                    } else {
                        var domain = "unknown"
                        var message = "unknown"
                        if let errorMessage =  result["message"] as? String {
                            message = errorMessage
                        }
                        if (400...499).contains(status) {
                            domain = "client"
                        } else if (500...599).contains(status) {
                            domain = "server"
                        }
                        let error = NSError(domain: domain, code: status, userInfo: [NSLocalizedDescriptionKey: message])
                        os_log("[FAIL] - %{private}@ - Server response failed : %{private}@", log: OSLog.networkService, type: .error, String(describing:self), error.localizedDescription)
                        completion?(.failure(error))
                    }
                    return
                } catch {
                    os_log("[FAIL] - %{private}@ - Server response failed : %{private}@", log: OSLog.networkService, type: .error, String(describing:self), error.localizedDescription)
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                os_log("[FAIL] - %{private}@ - Server response failed : %{private}@", log: OSLog.networkService, type: .error, String(describing:self), error.localizedDescription)
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }

}
