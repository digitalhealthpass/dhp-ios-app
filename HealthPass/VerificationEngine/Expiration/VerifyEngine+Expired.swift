//
//  VerifyEngine+Expired.swift
//  VerificationEngine
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import VerifiableCredential
import SwiftCBOR
import OSLog

extension VerifyEngine {
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: Public Methods

    /// Checks whether the VerifiableObject is expired.
    /// Compares the expiration date of VerifiableObject's credential, JWS or COSE with current date..
    ///
    public func isExpired() throws -> Bool {
        if let credential = verifiableObject?.credential {
            guard let expirationDateSting = credential.expirationDate else {
                os_log("Expiration - Credential - No Expiration Data Available ", log: OSLog.VerifyEngineOSLog, type: .info)
                return false
            }
            
            let currentUTCDate = Date().toUTCTime()
            let expirationDate = expirationDateSting.credentialExpiryDate
            
            let order = Calendar.current.compare(currentUTCDate, to: expirationDate, toGranularity: .second)
            if order == .orderedAscending {
                os_log("Expiration - Credential - Not Expired ", log: OSLog.VerifyEngineOSLog, type: .info)
                return false
            }
            
            os_log("Expiration - Credential - Expired ", log: OSLog.VerifyEngineOSLog, type: .info)
            return true
        } else if let jws = verifiableObject?.jws {
            guard let expDateTimeInterval = jws.payload?.exp else {
                os_log("Expiration - JWS - No Expiration Data Available ", log: OSLog.VerifyEngineOSLog, type: .info)
                return false
            }
            
            let currentDate = Date()
            let expirationDate = Date(timeIntervalSince1970: TimeInterval(expDateTimeInterval))
            
            let order = Calendar.current.compare(currentDate, to: expirationDate, toGranularity: .second)
            
            if order == .orderedAscending {
                os_log("Expiration - JWS - Not Expired ", log: OSLog.VerifyEngineOSLog, type: .info)
                return false
            }
            
            os_log("Expiration - JWS - Expired ", log: OSLog.VerifyEngineOSLog, type: .info)
            return true
        } else if let cose = verifiableObject?.cose {
            guard let cwt = CWT(from: cose.payload) else {
                return false
            }
            
            guard let expDateTimeInterval = cwt.exp else {
                os_log("Expiration - Cose - No Expiration Data Available ", log: OSLog.VerifyEngineOSLog, type: .info)
                return false
            }
            
            let currentDate = Date()
            let expirationDate = Date(timeIntervalSince1970: TimeInterval(expDateTimeInterval))
            let order = Calendar.current.compare(currentDate, to: expirationDate, toGranularity: .second)
            
            if order == .orderedAscending {
                os_log("Expiration - Cose - Not Expired ", log: OSLog.VerifyEngineOSLog, type: .info)
                return false
            }
            
            os_log("Expiration - Cose - Expired ", log: OSLog.VerifyEngineOSLog, type: .info)
            return true
        }
        
        os_log("Expiration - Unknown ", log: OSLog.VerifyEngineOSLog, type: .info)
        return false
    }
    
}
