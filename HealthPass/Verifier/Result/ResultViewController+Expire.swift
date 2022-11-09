//
//  ResultViewController+Expire.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import PromiseKit
import OSLog

extension ResultViewController {
    
    internal func isExpired() -> Promise<Void> {
        return Promise { resolver in
            do {
                if (try self.verifyEngine.isExpired()) {
                    os_log("isExpired - True ", log: OSLog.resultViewControllerOSLog, type: .info)
                    resolver.reject(NSError.credentialExpired)
                } else {
                    resolver.fulfill_()
                }
            } catch {
                os_log("isExpired - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, error.localizedDescription)
                resolver.reject(error)
            }
        }
    }
    
}
