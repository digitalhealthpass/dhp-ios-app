//
//  CredentialDetailsTableViewController+Status.swift
//  Holder
//
//  Created by Yevtushenko Valeriia on 24.01.2022.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import PromiseKit
import OSLog

extension CredentialDetailsTableViewController {
    
    func isNotRevoked() -> Promise<Void> {
        return Promise { resolver in
        
            guard let did = package?.credential?.id else {
                resolver.reject(NSError.credentialRevokeNoProperties)
                return
            }
            
            CredentialService().getRevokeStatus(for: did) { result in
                switch result {
                case .success(let revokeStatus):
                    guard let revokePayload = revokeStatus["payload"] as? [String : Any],
                          let isRevoked = self.isRevoked(payload: revokePayload), isRevoked else {
                        resolver.fulfill_()
                        return
                    }
                    
                    resolver.reject(NSError.credentialRevoked)
                case .failure(_):
                    resolver.fulfill_()
                }
            }
        }
    }
    
    private func isRevoked(payload: [String : Any]) -> Bool? {
        guard let exists = payload["exists"] as? Int else {
            return nil
        }
        
        return (exists == 1)
    }
}
