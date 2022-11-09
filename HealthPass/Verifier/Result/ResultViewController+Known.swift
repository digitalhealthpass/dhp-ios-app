//
//  ResultViewController+Known.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import PromiseKit
import OSLog
import VerificationEngine

extension ResultViewController {
    
    internal func isKnown() -> Promise<Void> {
        return Promise { resolver in
            
            let supportedTypes = DisplayService().getSupportedTypes()
            
            do {
                if (try self.verifyEngine.isKnown(supportedTypes)) {
                    resolver.fulfill_()
                } else {
                    os_log("isKnown - False ", log: OSLog.resultViewControllerOSLog, type: .info)
                    resolver.reject(NSError.credentialUnknown)
                }
            } catch {
                os_log("isKnown - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, error.localizedDescription)
                resolver.reject(error)
            }
        }
    }
    
    internal func isKnown(with verifierConfiguration: VerifierConfiguration) -> Promise<SpecificationConfiguration> {
        return Promise { resolver in
            
            guard var specificationConfigurations = verifierConfiguration.specificationConfigurations else {
                resolver.reject(NSError.credentialUnknown)
                return
            }
            
            verifierConfiguration.disabledSpecifications?.forEach { disabledConfiguration in
                specificationConfigurations = specificationConfigurations.filter({ $0.id != disabledConfiguration.id })
            }
            
            for configuration in specificationConfigurations {
                if let rule = configuration.classifierRule,
                    let rulesResponse = try? self.verifyEngine.doesMatchRules(rules: [rule]),
                    let result = rulesResponse.result, result {
                    resolver.fulfill(configuration)
                    return
                }
            }
            
            resolver.reject(NSError.credentialUnknown)
            return
        }
    }
    
}
