//
//  NSError+Verification.swift
//  VerificationEngine
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

//Credential Expiry
extension NSError {
    public static let credentialExpired = NSError(domain: "Credential Expired", code: 2402, userInfo: [NSLocalizedDescriptionKey: "verification.credentialExpired".localized])
    
    public static let credentialExpiryNoDate = NSError(domain: "Credential Expired", code: 2401, userInfo: [NSLocalizedDescriptionKey: "verification.credentialExpired.missingDate".localized])
}

//Credential Signature
extension NSError {
    public static let credentialSignatureNoProperties = NSError(domain: "Invalid Signature", code: 3401, userInfo: [NSLocalizedDescriptionKey: "verification.invalidSignature.notFound".localized])
    
    public static let credentialSignatureNoKey = NSError(domain: "Invalid Signature", code: 3402, userInfo: [NSLocalizedDescriptionKey: "verification.invalidSignature.keysNotFound".localized])
    
    public static let credentialSignatureInvalidSignatureData = NSError(domain: "Invalid Signature", code: 3403, userInfo: [NSLocalizedDescriptionKey: "verification.invalidSignature.invalidSignatureData".localized])
    
    public static let credentialSignatureInvalidCredentialData = NSError(domain: "Invalid Signature", code: 3404, userInfo: [NSLocalizedDescriptionKey: "verification.invalidSignature.invalidData".localized])
    
    public static let credentialSignatureUnsupportedKey = NSError(domain: "Invalid Signature", code: 3405, userInfo: [NSLocalizedDescriptionKey: "verification.invalidSignature.unsupportedKeys".localized])
    
    public static let credentialSignatureUnavailableKey = NSError(domain: "Invalid Signature", code: 3407, userInfo: [NSLocalizedDescriptionKey: "verification.invalidSignature.unavailableKeys".localized])

    public static let credentialSignatureFailed = NSError(domain: "Invalid Signature", code: 3406, userInfo: [NSLocalizedDescriptionKey: "verification.invalidSignature.ecSignatureNoMatch".localized])
}

//Credential Revoke
extension NSError {
    public static let credentialRevokeNoProperties = NSError(domain: "Credential Revoke", code: 4401, userInfo: [NSLocalizedDescriptionKey: "verification.credentialRevoke.propertiesNotFound".localized])
    
    public static let credentialRevoked = NSError(domain: "Credential Revoke", code: 4402, userInfo: [NSLocalizedDescriptionKey: "verification.credentialRevoke.issuerRevoked".localized])
    
    public static let credentialRevokedSkip = NSError(domain: "Credential Revoke", code: 4403, userInfo: [NSLocalizedDescriptionKey: "verification.credentialRevoke.skipped".localized])
}

//Credential Trusted
extension NSError {
    public static let issuerNotTrusted = NSError(domain: "Issuer UnTrusted", code: 5402, userInfo: [NSLocalizedDescriptionKey: "verification.credentialRevoke.issuerRevoked".localized])
    
    public static let credentialUnknown = NSError(domain: "Credential Unknown", code: 5403, userInfo: [NSLocalizedDescriptionKey: "Credential Unknown"])
}

//Credential Rules Match
extension NSError {
    public static let credentialRules = NSError(domain: "Credential Rules Not Match", code: 6401, userInfo: [NSLocalizedDescriptionKey: "Credential rules did not match"])
}

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
