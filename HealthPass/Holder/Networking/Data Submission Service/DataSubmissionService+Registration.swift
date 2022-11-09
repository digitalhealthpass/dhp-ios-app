//
//  DataSubmissionService+Registration.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire

extension DataSubmissionService {
    
    private func registerRequest(for organization: String, with dictionary: [String: Any]) -> DataRequest? {
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.dataSubmission)
        url.appendPathComponent(Network.onboarding)
//        url.appendPathComponent(organization)
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = httpHeaders

        var httpBodyDictionary = dictionary
        
        if let locations = readLocationFile(),
           let requiredLocation = locations.filter ({ ($0["State"] as? String) == (dictionary["location"] as? String) }).first,
           let requiredLocationCode = requiredLocation["Code"] as? String {
            httpBodyDictionary["location"] = requiredLocationCode
        }
        
        let httpBodyData = try? JSONSerialization.data(withJSONObject: httpBodyDictionary, options: .prettyPrinted)
        request.httpBody = httpBodyData
        
        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    private func readLocationFile() -> [[String: Any]]? {
        guard let path = Bundle.main.path(forResource: String("location"), ofType: String("json")) else {
            return nil
        }
        
        let fileUrl = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: fileUrl, options: .mappedIfSafe) else {
            return nil
        }
        
        let locations = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        return locations
    }

    @discardableResult
    public func register(for organization: String, with dictionary: [String: Any], completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
       
        #if HOLDER
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.register(for: organization, with: dictionary, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        #endif

        guard let dataRequest = DataSubmissionService().registerRequest(for: organization, with: dictionary) else {
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    print("[FAIL] - Register - Server response failed : Invaild response data")
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        print("[FAIL] - Register - Invalid Server response format")
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                       let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Data Submission"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - Register - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    print(String(format: "[RESPONSE] - Register: %@", result))
                    completion?(.success(result))
                    return
                } catch {
                    print("[FAIL] - Register - Server response failed : \(error.localizedDescription)")
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                print("[FAIL] - Register - Server response failed : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }
    
}
