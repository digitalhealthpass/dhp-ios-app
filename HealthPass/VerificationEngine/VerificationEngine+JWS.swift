//
//  VerificationEngine+JWS.swift
//  VerificationEngine
//
//  Created by John Martino on 2021-06-28.
//

import Foundation
import VerifiableCredential
import PromiseKit

extension VerifyEngine {
    
    @discardableResult
    public func checkExpiry(for jws: JWS) -> Promise<(Bool?, String)> {
        return Promise<(Bool?, String)>(resolver: { resolver in
            guard let expDateTimeInterval = jws.payload?.exp else {
                resolver.fulfill((nil, NSError.credentialExpiryNoDate.localizedDescription))
                return
            }
            
            let currentDate = Date()
            let expirationDate = Date(timeIntervalSince1970: TimeInterval(expDateTimeInterval))
            
            let order = Calendar.current.compare(currentDate, to: expirationDate, toGranularity: .second)
            if order == .orderedAscending {
                resolver.fulfill((false, "verification.notExpired".localized))
                return
            }
            
            resolver.reject(NSError.credentialExpired)
        })
    }
    
}
