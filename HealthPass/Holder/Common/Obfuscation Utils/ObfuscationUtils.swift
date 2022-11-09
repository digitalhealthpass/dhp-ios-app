//
//  ObfuscationUtils.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

class ObfuscationUtils {
    
    public func checkObfuscation(credential: Credential) -> (Bool, String) {
        guard let obfuscation = credential.obfuscation else {
            return (true, "obf.ok".localized)
        }
        
        guard let subject = credential.extendedCredentialSubject?.rawDictionary else {
            return (false, "obf.credSubjNotFound".localized)
        }
        
        for obfuscatedField in obfuscation {
            guard let path = obfuscatedField.path else {
                return (false, "obf.pathFieldNotFound".localized)
            }
            
            guard let mac = self.resolveJsonPath(jsonDictionary: subject, keyPath: path) else {
                return (false, String(format: "obf.pathNotFoundFormat".localized, "\(path)"))
            }
            
            guard let val = obfuscatedField.val, let nonce = obfuscatedField.nonce else {
                return (false, "obf.valOrNonceNotFound".localized)
            }
            
            let verification = CredentialCryptoUtils().verifyHS256Mac(plainValue: val, base64UrlKey: nonce, base64UrlMac: mac)
            
            if !verification {
                return (false, String(format: "obf.fieldPathCheckFormat".localized, "\(path)"))
            }
        }
        
        return (true, "obf.ok".localized)
    }
    
    private func resolveJsonPath(jsonDictionary: [String: Any], keyPath: String) -> String? {
        let totalCount = keyPath.split(separator: ".").count
        var current: [String: Any] = jsonDictionary
        
        for (index, component) in keyPath.split(separator: ".").enumerated() {
            if index == totalCount - 1 {
                return current[String(component)] as? String
            } else {
                if let nested = current[String(component)] as? [String: Any] {
                    current = nested
                } else {
                    return nil
                }
            }
        }
        
        return nil
    }
}
