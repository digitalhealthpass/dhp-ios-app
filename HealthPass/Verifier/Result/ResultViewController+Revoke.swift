//
//  ResultViewController+Revoke.swift
//  Verifier
//
//  Created by John Martino on 2021-09-08.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import PromiseKit
import OSLog
import VerificationEngine

extension ResultViewController {
    
    internal func isNotRevoked(with specificationConfiguration: SpecificationConfiguration? = nil) -> Promise<SpecificationConfiguration?> {
        self.specificationConfiguration = specificationConfiguration
        
        return Promise { resolver in
            guard verifiableObject?.type == .IDHP || verifiableObject?.type == .GHP || verifiableObject?.type == .VC else {
                os_log("isNotRevoked - %{public}@", log: OSLog.resultViewControllerOSLog, type: .info, "Revoke check not required")
                resolver.fulfill(specificationConfiguration)
                return
            }
            
            guard let did = verifiableObject?.credential?.id else {
                os_log("isNotRevoked - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, "No Issuer Object")
                resolver.reject(NSError.credentialRevokeNoProperties)
                return
            }
            
            CredentialService().getRevokeStatus(for: did) { result in
                switch result {
                case .success(let revokeStatus):
                    guard let revokePayload = revokeStatus["payload"] as? [String : Any] else {
                        os_log("isNotRevoked - Payload Unavailable ", log: OSLog.resultViewControllerOSLog, type: .info)
                        resolver.fulfill(specificationConfiguration)
                        return
                    }
                    
                    guard let isRevoked = self.isRevoked(payload: revokePayload) else {
                        os_log("isNotRevoked - Status Unavailable ", log: OSLog.resultViewControllerOSLog, type: .info)
                        resolver.fulfill(specificationConfiguration)
                        return
                    }
                    
                    if isRevoked {
                        os_log("isNotRevoked - Credential Revoked ", log: OSLog.resultViewControllerOSLog, type: .info)
                        resolver.reject(NSError.credentialRevoked)
                    } else {
                        os_log("isNotRevoked - Credential Not Revoked ", log: OSLog.resultViewControllerOSLog, type: .info)
                        resolver.fulfill(specificationConfiguration)
                    }
                    
                case .failure(let error):
                    os_log("isNotRevoked - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, error.localizedDescription)
                    resolver.fulfill(specificationConfiguration)
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
