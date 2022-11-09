//
//  WalletTableViewController+AppleHealth.swift
//  Holder
//
//  Created by Gautham Velappan on 12/2/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import HealthKit

extension WalletTableViewController {
    
    internal func showAppleHealth() {
        if #available(iOS 15, *) {
            let healthStore = HKHealthStore()
            let credentialTypes = ["https://smarthealth.cards#immunization", "https://smarthealth.cards#covid19"]
            
            // For demo, ask for all records, regardless of their relevant date.
            let dateInterval = DateInterval(start: .distantPast, end: .now)
            let predicate = HKQuery.predicateForVerifiableClinicalRecords(withRelevantDateWithin: dateInterval)
            
            let query = HKVerifiableClinicalRecordQuery(recordTypes: credentialTypes, predicate: predicate) { (_, samples, error) in
                if let error = error as? HKError {
                    if error.code != HKError.errorUserCanceled {
                        DispatchQueue.main.async {
                            let title = "wallet.HealthKitError.title".localized
                            let message = error.localizedDescription
                            self.showErrorAlert(title: title, message: message)
                        }
                    }
                    
                    return
                }
                
                guard let verifiableClinicalRecords = samples else {
                    DispatchQueue.main.async {
                        let title = "wallet.HealthKitError.title".localized
                        let message = "wallet.HealthKitError.message".localized
                        self.showErrorAlert(title: title, message: message)
                    }
                    
                    return
                }
                
                let jwsRepresentationRecords = verifiableClinicalRecords.compactMap({ $0.jwsRepresentation })
                
                guard !(jwsRepresentationRecords.isEmpty) else {
                    DispatchQueue.main.async {
                        let title = "wallet.HealthKitError.title".localized
                        let message = "wallet.HealthKitError.message".localized
                        self.showErrorAlert(title: title, message: message)
                    }
                    
                    return
                }
                
                DispatchQueue.main.async {
                    self.showScanComplete(with: jwsRepresentationRecords)
                }
            }
            
            // Run the query.
            healthStore.execute(query)
        }
    }
    
}
