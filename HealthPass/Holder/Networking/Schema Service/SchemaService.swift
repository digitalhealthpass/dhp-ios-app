//
//  ScanService.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import Alamofire
import os.log

extension OSLog {
    static let schemaService = OSLog(subsystem: subsystem, category: "schemaService")
}

class SchemaService: Network {
    
    private func SchemaServiceRequest(issuerId: String? = nil) -> DataRequest? {
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.healthPass)
        url.appendPathComponent(Network.schema)
        if let issuerId = issuerId {
            url.appendPathComponent(issuerId)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        
        var headerFields = httpHeaders
        headerFields["did"] = issuerId
        
        request.allHTTPHeaderFields = headerFields
        
        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    private func ConsentReceiptSchemaRequest(regEntity: String, holderId: String) -> DataRequest? {
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.dataSubmission)
        url.appendPathComponent(Network.organization)
        url.appendPathComponent(regEntity)
        url.appendPathComponent(Network.consentReceipt)
        url.appendPathComponent(holderId)
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.allHTTPHeaderFields = httpHeaders
        
        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    private func ConsentRevokeSchemaRequest(regEntity: String, holderId: String) -> DataRequest? {
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.dataSubmission)
        url.appendPathComponent(Network.organization)
        url.appendPathComponent(regEntity)
        url.appendPathComponent(Network.consentRevoke)
        url.appendPathComponent(holderId)
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.allHTTPHeaderFields = httpHeaders
        
        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    /// Network layer call to get schema info for a given id
    ///
    /// - parameter did: credential's unique identifier
    ///
    /// - parameter completion: A closure of type JSON dictionary to be executed once the request has finished.
    ///
    @discardableResult
    public func getSchema(schemaId: String,
                          completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.getSchema(schemaId: schemaId, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        
        guard let dataRequest = SchemaService().SchemaServiceRequest(issuerId: schemaId) else {
            os_log("[FAIL] - Get Schema - Server response failed : Invaild data request", log: OSLog.schemaService, type: .error)
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            self.handleResponse(response, withCompletion: completion)
        }
        
        return dataRequest
    }
    
    /// Network layer call to get all schema for the issuer
    ///
    ///
    /// - parameter completion: A closure of type JSON dictionary to be executed once the request has finished.
    ///
    @discardableResult
    public func getAllSchema(completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.getAllSchema(completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        
        guard let dataRequest = SchemaService().SchemaServiceRequest() else {
            os_log("[FAIL] - Get All Schema - Server response failed : Invaild data request", log: OSLog.schemaService, type: .error)
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            self.handleResponse(response, withCompletion: completion)
        }
        
        return dataRequest
    }
    
    /// Network layer call to get consent revoke schema for contact
    ///
    ///
    /// - parameter completion: A closure of type JSON dictionary to be executed once the request has finished.
    ///
    @discardableResult
    public func getConsentRevokeSchemaFor(regEntity: String, holderId: String, completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.getConsentRevokeSchemaFor(regEntity: regEntity, holderId: holderId, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        
        guard let dataRequest = SchemaService().ConsentRevokeSchemaRequest(regEntity: regEntity, holderId: holderId) else {
            os_log("[FAIL] - ConsentRevokeSchemaRequest - Server response failed : Invaild data request", log: OSLog.schemaService, type: .error)
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            self.handleResponse(response, withCompletion: completion)
        }
    
        return dataRequest
    }
    
    /// Network layer call to get consent receipt schema for contact
    ///
    ///
    /// - parameter completion: A closure of type JSON dictionary to be executed once the request has finished.
    ///
    @discardableResult
    public func getConsentReceiptSchemaFor(regEntity: String, holderId: String, completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.getConsentReceiptSchemaFor(regEntity: regEntity, holderId: holderId, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        
        guard let dataRequest = SchemaService().ConsentReceiptSchemaRequest(regEntity: regEntity, holderId: holderId) else {
            os_log("[FAIL] - ConsentReceiptSchemaRequest - Server response failed : Invaild data request", log: OSLog.schemaService, type: .error)
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            self.handleResponse(response, withCompletion: completion)
        }
    
        return dataRequest
    }
    
    private func handleResponse(_ response: DataResponse<Any>, withCompletion completion: CompletionDictionaryHandler?){
        switch response.result {
        case .success:
            guard let data = response.data else {
                os_log("[FAIL] - Server response failed : Invaild response data", log: OSLog.schemaService, type: .error)
                completion?(.failure(NSError.missingDataResponseError))
                return
            }
            
            do {
                let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                guard let result = decoded as? [String: Any] else {
                    os_log("[FAIL] - Invalid Server response format", log: OSLog.schemaService, type: .error)
                    completion?(.failure(NSError.invalidDataResponseError))
                    return
                }
                
                if let errorDictionary = result["error"] as? [String: Any],
                    let errorMessage =  errorDictionary["message"] as? String {
                    let error = NSError(domain: String("Schema"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    os_log("[FAIL] - Server response failed : %{private}@", log: OSLog.schemaService, type: .error, error.localizedDescription)
                    completion?(.failure(error))
                    return
                }
                os_log("[RESPONSE]: %{private}@", log: OSLog.schemaService, type: .info, result)
                completion?(.success(result))
                return
            } catch {
                os_log("[FAIL] - Server response failed : %{private}@", log: OSLog.schemaService, type: .error, error.localizedDescription)
                completion?(.failure(error))
            }
            
        case let .failure(error):
            os_log("[FAIL] - Server response failed : %{private}@", log: OSLog.schemaService, type: .error, error.localizedDescription)
            completion?(.failure(error))
        }
    }
}
