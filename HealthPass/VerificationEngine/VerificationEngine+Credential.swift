//
//  VerificationEngine+Credential.swift
//  VerificationEngine
//
//  Created by John Martino on 2021-06-28.
//

import Foundation
import VerifiableCredential
import PromiseKit

extension VerifyEngine {
    
    @discardableResult
    public func checkExpiry(for credential: Credential) -> Promise<(Bool?, String)> {
        return Promise<(Bool?, String)>(resolver: { resolver in
            guard let expirationDateSting = credential.expirationDate else {
                resolver.fulfill((nil, NSError.credentialExpiryNoDate.localizedDescription))
                return
            }

            let currentUTCDate = Date().toUTCTime()
            let expirationDate = expirationDateSting.credentialExpiryDate

            let order = Calendar.current.compare(currentUTCDate, to: expirationDate, toGranularity: .second)
            if order == .orderedAscending {
                resolver.fulfill((false, "verification.notExpired".localized))
                return
            }

            resolver.reject(NSError.credentialExpired)
        })
    }
    
}
