//
//  ResultViewController+Rules.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import VerificationEngine
import PromiseKit
import OSLog

extension ResultViewController {
    
    internal func doesMatchRules() -> Promise<Void> {
        return Promise { resolver in
            guard let verifiableObject = self.verifiableObject else {
                os_log("doesMatchRules - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, "No Rules Objects")
                resolver.reject(NSError.credentialSignatureNoProperties)
                return
            }
            
            if let rules = RuleService().getRule(for: verifiableObject.type), !(rules.isEmpty) {
                
                let rulesResponse = try self.verifyEngine.doesMatchRules(rules: rules)
                
                self.successfulRules = rulesResponse.successfulRules
                self.failedRules = rulesResponse.failedRules
                
                guard let result = rulesResponse.result else {
                    self.type = .VC
                    self.fallbackRules(with: resolver)
                    return
                }
                
                if (result) {
                    resolver.fulfill_()
                } else {
                    os_log("doesMatchRules - True ", log: OSLog.resultViewControllerOSLog, type: .info)
                    resolver.reject(NSError.credentialRules)
                }
            } else {
                os_log("doesMatchRules - No Rules Available", log: OSLog.resultViewControllerOSLog, type: .error)
                resolver.fulfill_()
            }
        }
    }
    
    private func fallbackRules(with resolver: Resolver<Void>) {
        guard let rules = RuleService().getRule(for: .VC), !(rules.isEmpty) else {
            resolver.fulfill_()
            return
        }
        
        guard let rulesResponse = try? self.verifyEngine.doesMatchRules(rules: rules) else {
            resolver.fulfill_()
            return
        }
       
        self.successfulRules = rulesResponse.successfulRules
        self.failedRules = rulesResponse.failedRules

        if let result = rulesResponse.result, (result) {
            resolver.fulfill_()
        } else {
            os_log("doesMatchRules - True ", log: OSLog.resultViewControllerOSLog, type: .info)
            resolver.reject(NSError.credentialRules)
        }
    }
    
    
    internal func doesMatchRules(with specificationConfiguration: SpecificationConfiguration?) -> Promise<SpecificationConfiguration?> {
        self.specificationConfiguration = specificationConfiguration
        
        return Promise { resolver in
            if var rules = specificationConfiguration?.rules, !(rules.isEmpty) {
               
                if let disabledRules = DataStore.shared.currentVerifierConfiguration?.disabledRules?.filter({ $0.specID == specificationConfiguration?.id }), !(disabledRules.isEmpty) {
                    disabledRules.forEach { disabledRule in
                        rules = rules.filter({ $0.id != disabledRule.id })
                    }
                }
                
                
                var valueSet: [ValueSet]?
                if let globalValueSet = DataStore.shared.currentVerifierConfiguration?.valueSets, !(globalValueSet.isEmpty) {
                    valueSet = globalValueSet
                }
                
                let rulesResponse = try self.verifyEngine.doesMatchRules(rules: rules, with: valueSet)
                
                self.successfulRules = rulesResponse.successfulRules
                self.failedRules = rulesResponse.failedRules
                
                if let result = rulesResponse.result, result {
                    resolver.fulfill(specificationConfiguration)
                } else {
                    os_log("doesMatchRules - True ", log: OSLog.resultViewControllerOSLog, type: .info)
                    resolver.reject(NSError.credentialRules)
                }
            } else {
                os_log("doesMatchRules - No Rules Available", log: OSLog.resultViewControllerOSLog, type: .error)
                resolver.fulfill(specificationConfiguration)
            }
        }
    }
    
}
