//
//  Credential+Wallet.swift
//  Holder
//
//  Created by Gautham Velappan on 8/20/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit
import QRCoder

extension Credential {
    
    // Derived Data
    
    var extendedCredentialSubject: CredentialSubject? {
        guard let credentialSubject = credentialSubject else {
            return nil
        }
        
        return CredentialSubject(value: credentialSubject)
    }

    var issuanceDateValue: Date? {
        guard let issuanceDate = issuanceDate else {
            return nil
        }
        
        return Date.dateFromString(dateString: issuanceDate, dateFormatPattern: .credentialExpirationDateFormat)
    }
    
    var expirationDateValue: Date? {
        guard let expirationDate = expirationDate else {
            return nil
        }
        
        return Date.dateFromString(dateString: expirationDate, dateFormatPattern: .credentialExpirationDateFormat)
    }
    
    var isExpired: Bool {
        guard let expirationDateValue = expirationDateValue else {
            return false
        }
        
        let currentDate = Date()
        let order = Calendar.current.compare(currentDate, to: expirationDateValue, toGranularity: .second)
        return !(order == .orderedAscending)
    }
    
}
