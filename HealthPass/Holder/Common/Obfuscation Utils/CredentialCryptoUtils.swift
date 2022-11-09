//
//  CredentialPKIUtils.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import JOSESwift
import CryptoKit

class CredentialCryptoUtils {
    
    public func verifyECDSASignature(credential: Credential, pubKey: IssuerPublicKeyJwk) -> Bool {
        guard let signature = credential.proof?.signatureValue else {
            return false
        }
        
        var unsignedCredential = credential
        unsignedCredential.proof?.signatureValue = nil
        unsignedCredential.obfuscation = nil
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        
        guard let unsignedRawData = try? encoder.encode(unsignedCredential) else {
            return false
        }
        
        guard let rawSignature = Data(base64Encoded: self.base64urlToBase64(base64url: signature)) else {
            return false
        }
        
        guard let nativePubKey = self.convertJwkToSecKey(pubKey: pubKey) else {
            return false
        }
        
        let result =  SecKeyVerifySignature(nativePubKey, SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256, unsignedRawData as CFData, rawSignature as CFData, nil)
        
        return result
    }
    
    public func verifyHS256Mac(plainValue: String, base64UrlKey: String, base64UrlMac: String) -> Bool {
        guard let macdata = Data(base64Encoded: self.base64urlToBase64(base64url: base64UrlMac)) else {
            return false
        }
        
        guard let keydata = Data(base64Encoded: self.base64urlToBase64(base64url: base64UrlKey)) else {
            return false
        }
        
        let key = CryptoKit.SymmetricKey.init(data: keydata)
        
        if #available(iOS 13.2, *) {
            return HMAC<SHA256>.isValidAuthenticationCode(macdata, authenticating: plainValue.data(using: .utf8)! as NSData, using: key)
        } else {
            //TODO: Find older version
            return false
        }
    }
    
    private func base64urlToBase64(base64url: String) -> String {
        var base64 = base64url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        
        return base64
    }
    
    private func convertJwkToSecKey(pubKey: IssuerPublicKeyJwk) -> SecKey? {
        let encoder = JSONEncoder()
        guard let jwkJson = try? encoder.encode(pubKey) else {
            return nil
        }
        
        guard let ecpubkey = try? ECPublicKey(data: jwkJson) else {
            return nil
        }
        
        guard let key = try? ecpubkey.converted(to: SecKey.self) else {
            return nil
        }
        
        return key
    }
}
