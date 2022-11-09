//
//  VerifyEngine+Rules.swift
//  VerificationEngine
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import OSLog
import jsonlogic
import JSON

extension VerifyEngine {
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: Public Methods
    
    /// Checks whether Verifiable Object matches rules parameter
    ///
    public func doesMatchRules(rules: [Rule], with valueSets: [ValueSet]? = nil) throws -> (result: Bool?, successfulRules: [Rule]?, failedRules: [Rule]?) {
        guard let payloadJSON = self.getPayloadJSON(with: valueSets) else {
            return (false, nil, nil)
        }
        
        var successfulRules = [Rule]()
        var failedRules = [Rule]()
        var results = [Bool]()
       
        for rule in rules {
            if let ruleJSONLogic = self.getRuleJSONLogic(for: rule)  {
                if let jsonLogicStringResult: String = try? ruleJSONLogic.applyRuleInternal(to: payloadJSON), jsonLogicStringResult.lowercased() == String("unknown") {
                    return (nil, nil, nil)
                } else {
                    if let jsonLogicBoolResult: Bool = try? ruleJSONLogic.applyRuleInternal(to: payloadJSON) {
                        if !jsonLogicBoolResult {
                            failedRules.append(rule)
                        } else {
                            successfulRules.append(rule)
                        }
                        results.append(jsonLogicBoolResult)
                    } else {
                        failedRules.append(rule)
                        results.append(false)
                    }
                }
            } else {
                failedRules.append(rule)
            }
        }
        
        return (!(results.contains(false)), successfulRules, failedRules)
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods

    private func getPayloadJSON(with valueSets: [ValueSet]? = nil) -> JSON? {
        guard let payload = verifiableObject?.payload as? [String: Any] else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        let dateString = dateFormatter.string(from: Date())
        
        var external: [String: Any] = ["validationClock": dateString]
        
        valueSets?.forEach { valueSet in
            if let key = valueSet.name, let items = valueSet.items?.compactMap({ $0.value }) {
                let convertedItems: [Any] = items.compactMap({ Int($0) ?? Float($0) ?? $0 })
                external[key] = convertedItems
            }
        }
        
        let data = [ "payload": payload,
                     "external": external ]
        
        let payloadJSON = JSON(data)

        return payloadJSON
    }
    
    private func getRulesJSONLogic(for rules: [Rule]) -> [JsonLogic]? {
        let rulesPredicateStrings = rules.compactMap({ $0.predicate })
        let rulesPredicateData = rulesPredicateStrings.compactMap { $0.data(using: .utf8) }
        let rulesPredicateJSON = rulesPredicateData.compactMap { try? JSONSerialization.jsonObject(with: $0, options : .allowFragments) as? [String: Any] }
        
        let rulesJSON = rulesPredicateJSON.compactMap { JSON($0) }
        
        let rulesJSONLogic = rulesJSON.compactMap { try? JsonLogic($0) }
        
        return rulesJSONLogic
    }
    
    private func getRuleJSONLogic(for rule: Rule) -> JsonLogic? {
        guard let rulesPredicate = rule.predicate else { return nil }
        
        guard let rulesPredicateData = rulesPredicate.data(using: .utf8) else { return nil }
        
        guard let rulesPredicateJSON =  try? JSONSerialization.jsonObject(with: rulesPredicateData, options : .allowFragments) as? [String: Any] else { return nil }
        
        let rulesJSON = JSON(rulesPredicateJSON)
        
        guard let rulesJSONLogic = try? JsonLogic(rulesJSON) else { return nil }
        
        return rulesJSONLogic
    }

}
