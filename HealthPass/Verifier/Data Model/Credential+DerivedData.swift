//
//  Credential+DerivedData.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import VerifiableCredential

extension Credential {
    
    // Derived Data
    
    public var isExpired: Bool {
        guard let expirationDateValue = expirationDate?.credentialExpirationDate else {
            return false
        }
        
        let currentDate = Date().toUTCTime()
        let order = Calendar.current.compare(currentDate, to: expirationDateValue, toGranularity: .second)
        return !(order == .orderedAscending)
    }
    
    public var base64String: String? {
        guard let rawString = rawString else {
            return nil
        }
        
        if let decodedData = Data(base64Encoded: rawString),
           let decodedString = String(data: decodedData, encoding: .utf8) {
            return decodedString.data(using: .utf8)?.base64EncodedString()
        } else {
            return rawString.data(using: .utf8)?.base64EncodedString()
        }
    }
    
}

extension Credential {
   
    //Determines if the verifier app can use this credential as the organization/verifier credential
    public var isOrganizationCredential: Bool {
        guard let type = credentialSubject?["type"] as? String else { return false }
        return (type == "VerifierCredential")
    }
    
    public var credentialSubjectType: String? {
        credentialSubject?["type"] as? String
    }
    
}

extension Credential {
   
    public var unsignedCredentialDictionary: [String: Any]? {
        var unsignedCredentialDictionary = rawDictionary
        
        //Remove signatureValue for verification process
        if var proof = unsignedCredentialDictionary?["proof"] as? [String: Any] {
            proof["signatureValue"] = nil
            unsignedCredentialDictionary?["proof"] = proof
        }
        
        //Remove obfuscation for verification process
        unsignedCredentialDictionary?["obfuscation"] = nil
        
        return unsignedCredentialDictionary
    }
    
}

extension String {
    
    var credentialExpirationDate: Date? {
        let credentialExpirationDateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = credentialExpirationDateFormat
        return dateFormatter.date(from: self)
    }
    
}
