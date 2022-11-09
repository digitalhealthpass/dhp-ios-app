//
//  DataSubmissionService+MFA+Verification.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire

extension DataSubmissionService {

    private func verifyMFARequest(for organization: String, with verificationCode: String) -> DataRequest? {
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.dataSubmission)
        url.appendPathComponent(Network.onboarding)
        url.appendPathComponent(Network.mfa)
        url.appendPathComponent(Network.verificationcode)
        url.appendPathComponent(verificationCode)

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = httpHeaders

        let httpBodyDictionary = ["organization": organization]
        let httpBodyData = try? JSONSerialization.data(withJSONObject: httpBodyDictionary, options: .prettyPrinted)
        request.httpBody = httpBodyData
        
        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }

    @discardableResult
    public func verifyMFA(for organization: String, with verificationCode: String, completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        #if HOLDER
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.verifyMFA(for: organization, with: verificationCode, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        #endif
        
        guard let dataRequest = DataSubmissionService().verifyMFARequest(for: organization, with: verificationCode) else {
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    print("[FAIL] - MFA Verify - Server response failed : Invaild response data")
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        print("[FAIL] - MFA Verify - Invalid Server response format")
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let httpStatusCode = response.response?.statusCode, !((200..<300).contains(httpStatusCode)),
                       let errorMessage =  result["message"] as? String {
                        let error = NSError(domain: String("Data Submission"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - MFA Verify - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                       let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Data Submission"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - MFA Verify - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    print(String(format: "[RESPONSE] - MFA Verify: %@", result))
                    completion?(.success(result))
                    return
                } catch {
                    print("[FAIL] - MFA Verify - Server response failed : \(error.localizedDescription)")
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                print("[FAIL] - MFA Verify - Server response failed : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }
    
}
