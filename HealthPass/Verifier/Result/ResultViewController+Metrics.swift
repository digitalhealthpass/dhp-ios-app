//
//  ResultViewController+Metrics.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import PromiseKit
import VerifiableCredential
import SwiftCBOR
import VerificationEngine

extension ResultViewController {
    
    internal func createMetrics() {
        var issuerId: String?
        var issuerName: String?
        var type: String?

        let spec = verifiableObject?.type.keyId ?? VCType.unknown.keyId
        let status = metricsStatus.rawValue

        if let configuration = DataStore.shared.currentVerifierConfiguration?.configuration?.value as? [String: Any],
           let credentialConfiguration = configuration[spec] as? [String: Any],
           let metricConfigurations = credentialConfiguration["metrics"] as? [[String: Any]], let metricConfigurations = metricConfigurations.first,
           let extractConfiguration = metricConfigurations["extract"] as? [String: Any] {
           
            if let issuerDIDPath = extractConfiguration["issuerDID"] as? String {
                issuerId = getValue(at: issuerDIDPath)
            }
            
            if let credentialTypePath = extractConfiguration["credentialType"] as? String  {
                type = getValue(at: credentialTypePath)
            }
            
            if let issuerNamePath = extractConfiguration["issuerName"] as? String  {
                issuerName = getValue(at: issuerNamePath)
            }
        }
        
        guard let metric = Metric(status: status, type: type, spec: spec, issuerId: issuerId, issuerName: issuerName) else {
            return
        }
        
        DataStore.shared.addMetric(metric: metric)
    }
    
    internal func createMetrics(with specificationConfiguration: SpecificationConfiguration?) {
        var issuerId: String?
        var issuerName: String?
        var type: String?

        let spec = verifiableObject?.type.keyId ?? VCType.unknown.keyId
        let status = metricsStatus.rawValue

        if let metric = specificationConfiguration?.metrics?.first,
           let extractConfiguration = metric.extract?.value as? [String: Any] {
           
            if let issuerDIDPath = extractConfiguration["issuerDID"] as? String {
                issuerId = getValue(at: issuerDIDPath)
            }
            
            if let credentialTypePath = extractConfiguration["credentialType"] as? String  {
                type = getValue(at: credentialTypePath)
            }
            
            if let issuerNamePath = extractConfiguration["issuerName"] as? String  {
                issuerName = getValue(at: issuerNamePath)
            }
        } else {
            issuerId = String("Unknown")
            issuerName = String("Unknown")
            type = String("Unknown")
        }
        
        guard let metric = Metric(status: status, type: type, spec: spec, issuerId: issuerId, issuerName: issuerName) else {
            return
        }
        
        DataStore.shared.addMetric(metric: metric)
    }

    internal func submitMetrics() {
        guard let aggregatedDictionary = DataStore.shared.getAggregatedMetricsDictionary(),
              aggregatedDictionary.count >= DataStore.MetricsUploadLimitCount else {
            return
        }
        
        MetricsService().submitMetrics(data: aggregatedDictionary, completion: { result in
            switch result {
            case .success:
                DataStore.shared.deleteAllMetrics()
                
            case .failure:
                //Check if Metrics goes over 1000 count with submit success - Apr 30 release, v1.0.2
                if let allMetricsDictionary = DataStore.shared.allMetricsDictionary,
                   allMetricsDictionary.count >= MetricsUploadCount.thousand.rawValue {
                    DataStore.shared.deleteAllMetrics()
                }
            }
        })
    }
    
    private func getValue(at path: String) -> String? {
        if let requiredPayload = verifiableObject?.payload as? [String: Any] {
            return getValue(at: path, for: requiredPayload)
        } else if let requiredPayload = verifiableObject?.payload as? [CBOR: CBOR] {
            return getValue(at: path, for: requiredPayload)
        }

        return nil
    }
    
}
