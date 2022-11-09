//
//  CredentialService+Create.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire

enum CredentialType: String {
    case string = "string"
    case encoded = "encoded"
}

struct CredentialHTTPBody: Codable {
    var schemaID: String
    var data: DataHTTPBody
    
    var obfuscation: [String]?
    
    var dataSource: String?
    var dataType: String?
}

struct DataHTTPBody: Codable {
    var person: PersonHTTPBody
    var labresult: LabResultHTTPBody
    
    var expiryDate: String?
}

struct PersonHTTPBody: Codable {
    var mrn: String
    var name: String
}

struct NameHTTPBody: Codable {
    var givenName: String
    var familyName: String
}

struct LabResultHTTPBody: Codable {
    var type: String
    var issueDate: String
    var loinc: String
    var result: String
}

extension CredentialService {
    
    private func createCredentialRequest(for credentialBody: CredentialHTTPBody, with type: CredentialType) -> DataRequest? {
        guard var urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.healthPass)
        url.appendPathComponent(Network.credentials)

        let typeQueryItem = URLQueryItem(name: "type", value: type.rawValue)
        urlComponents.queryItems = [typeQueryItem]

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = httpHeaders
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        
        request.httpBody = try? encoder.encode(credentialBody)
        
        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    @discardableResult
    public func createCredential(for credentialBody: CredentialHTTPBody, with type: CredentialType = CredentialType.string,
                                 completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        #if HOLDER
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.createCredential(for: credentialBody, with: type, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        #endif
        
        guard let dataRequest = CredentialService().createCredentialRequest(for: credentialBody, with: type) else {
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    print("[FAIL] - Create Credential - Server response failed : Invaild response data")
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        print("[FAIL] - Create Credential - Invalid Server response format")
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                        let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Client Error"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - Create Credential - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    print(String(format: "[RESPONSE] - Create Credential: %@", result))
                    completion?(.success(result))
                    return
                } catch {
                    print("[FAIL] - Create Credential - Server response failed : \(error.localizedDescription)")
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                print("[FAIL] - Create Credential - Server response failed : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }
    
}
