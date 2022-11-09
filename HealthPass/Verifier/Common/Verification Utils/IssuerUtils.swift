//
//  DIDUtils.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import VerifiableCredential
import VerificationEngine

class IssuerUtils {
    
    public func getIssuerPublicKeys(for did: String, and keyID: String,
                                    completion: @escaping (_ publicKey: [PublicKey]?, _ errorMessage: String?) -> Void) {
        
        //Check local cache
        if let allIssuers = DataStore.shared.allIssuer,
           let issuer = allIssuers.filter({ $0.id == did }).first,
           let publicKeys = issuer.publicKey?.filter({ $0.id == keyID }) {
            completion(publicKeys, nil)
            return
        } else {
            IssuerService().getIssuer(issuerId: did) { result in
                switch result {
                case .success(let json):
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    guard let payload = json["payload"] as? [String: Any] else {
                        completion(nil, String("verification.jsonDecodeFailed".localized))
                        return
                    }
                    
                    let issuer = Issuer(value: payload)
                    
                    //Cache the issuer
                    DataStore.shared.addNewIssuer(issuer: issuer)
                    
                    guard let publicKeys = issuer.publicKey?.filter({ $0.id == keyID }) else {
                        completion(nil, "verification.invalidKey".localized)
                        return
                    }
                    
                    completion(publicKeys, nil)
                    return
                    
                case .failure(let error):
                    completion(nil, error.localizedDescription)
                    return
                }
            }
        }
        
    }
    
}
