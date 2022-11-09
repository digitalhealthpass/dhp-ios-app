//
//  RuleService.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire
import VerifiableCredential
import VerificationEngine

//TODO: Replace local data fetch with APIs
class RuleService: Network {

    public func getRule(for type: VerifiableCredential.VCType) -> [Rule]? {
        
        guard let allConfiguration = DataStore.shared.currentVerifierConfiguration?.configuration?.value as? [String: Any] else {
            return nil
        }
        
        guard let configuration = allConfiguration[type.keyId] as? [String: Any] else {
            return nil
        }
        
        guard let ruleSet = configuration["rule-sets"] as? [[String: Any]] else {
            return nil
        }
        
        guard let rulesSetJSON = ruleSet.compactMap({ $0["rules"] }) as? [[[String: Any]]] else {
            return nil
        }
        
        var rulesJSON = [[String: Any]]()
        rulesSetJSON.forEach { json in
            rulesJSON.append(contentsOf: json)
        }
        
        let rulesData = rulesJSON.compactMap({ try? JSONSerialization.data(withJSONObject: $0, options: .prettyPrinted) })
        
        let rules = rulesData.compactMap({ try? Rule(data: $0) })
        
        return rules
    }
    
}
