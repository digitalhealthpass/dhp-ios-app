//
//  Date+Helper.swift
//  VerificationEngine
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

/**
 
 A collection of helper functions for validating Expiration Date
 
 */
extension Date {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Methods

    // Convert local time to UTC (or GMT)
    func toUTCTime() -> Date {
        let timezone = TimeZone.current
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }

    // Convert UTC (or GMT) to local time
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
}

extension String {
   
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties

    var credentialExpiryDate: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z"
        return dateFormatter.date(from: self) ?? Date()
    }
}
