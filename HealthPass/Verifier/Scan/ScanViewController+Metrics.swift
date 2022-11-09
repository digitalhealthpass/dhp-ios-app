//
//  ScanViewController+Metering.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import VerifiableCredential
import VerificationEngine

extension ScanViewController {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Methods
    
    @objc
    internal func submitMetrics() {
        guard let aggregatedDictionary = DataStore.shared.getAggregatedMetricsDictionary() else { return }
        
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
            
            self.metricsUploadTimer?.invalidate()
            self.metricsUploadTimer = nil
            self.startMetricsLimitCheck()
        })
    }
    
    internal func startMetricsLimitCheck() {
        metricsUploadTimer = Timer.scheduledTimer(timeInterval: DataStore.MetricsUploadLimitTimeInterval,
                                                  target: self,
                                                  selector: (#selector(ScanViewController.submitMetrics)),
                                                  userInfo: nil,
                                                  repeats: false)
    }
    
}
