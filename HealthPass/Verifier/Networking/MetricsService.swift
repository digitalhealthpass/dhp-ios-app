//
//  MetricsService.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire

class MetricsService: Network {
   
    public func getMetricsExtract(for spec: VerifiableCredential.VCType) -> [String: Any]? {
        
        guard let allConfiguration = DataStore.shared.currentVerifierConfiguration?.configuration?.value as? [String: Any] else {
            return nil
        }
        
        guard let configuration = allConfiguration[spec.keyId] as? [String: Any] else {
            return nil
        }
        
        guard let metricConfigurations = configuration["metrics"] as? [[String: Any]], let metricConfigurations = metricConfigurations.first else {
            return nil
        }
        
        guard let extractConfiguration = metricConfigurations["extract"] as? [String: Any] else {
            return nil
        }
        
        return extractConfiguration
    }

    //https://dev2.wh-hpass.dev.acme.com/api/v1/metering/metrics/add
    private func SubmitMetricsRequest(data: [[String: Any?]]) -> DataRequest? {
        guard let urlComponents = URLComponents(string: Network.baseURL) else { return nil }
        guard var url = urlComponents.url else { return nil }
        url.appendPathComponent(Network.metering)
        url.appendPathComponent(Network.metrics)
        url.appendPathComponent(Network.verifier)
        url.appendPathComponent(Network.batch)
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = httpHeaders

        let httpBodyDictionary = [ "data": data ]
        let httpBodyData = try? JSONSerialization.data(withJSONObject: httpBodyDictionary, options: .prettyPrinted)
        request.httpBody = httpBodyData

        let dataRequest = Network.sharedManager.request(request)
        
        return dataRequest
    }
    
    /// Network layer call to get schema info for a given id
    ///
    /// - parameter completion: A closure of type JSON dictionary to be executed once the request has finished.
    ///
    @discardableResult
    public func submitMetrics(data: [[String: Any?]],
                          completion: CompletionDictionaryHandler? = nil) -> DataRequest? {
        
        //Check access token validity, else login in the background
        guard DataStore.shared.isAccessTokenValid else {
            LoginService().refreshLogin { result in
                switch result {
                case .success:
                    self.submitMetrics(data: data, completion: completion)
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            
            return nil
        }
        
        guard let dataRequest = MetricsService().SubmitMetricsRequest(data: data) else {
            print("[FAIL] - Submit Metrics - Server response failed : Invalid data request")
            completion?(.failure(NSError.requestCreateError))
            return nil
        }
        
        dataRequest.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    print("[FAIL] - Submit Metrics - Server response failed : Invalid response data")
                    completion?(.failure(NSError.missingDataResponseError))
                    return
                }
                
                do {
                    let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let result = decoded as? [String: Any] else {
                        print("[FAIL] - Submit Metrics - Invalid Server response format")
                        completion?(.failure(NSError.invalidDataResponseError))
                        return
                    }
                    
                    if let errorDictionary = result["error"] as? [String: Any],
                        let errorMessage =  errorDictionary["message"] as? String {
                        let error = NSError(domain: String("Metrics"), code: 200, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("[FAIL] - Submit Metrics - Server response failed : \(error.localizedDescription)")
                        completion?(.failure(error))
                        return
                    }
                    
                    print(String(format: "[RESPONSE] - Submit Metrics: %@", result))
                    completion?(.success(result))
                    return
                } catch {
                    print("[FAIL] - Submit Metrics - Server response failed : \(error.localizedDescription)")
                    completion?(.failure(error))
                }
                
            case let .failure(error):
                print("[FAIL] - Submit Metrics - Server response failed : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
        
        return dataRequest
    }

    
}
