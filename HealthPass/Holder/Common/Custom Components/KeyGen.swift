//
//  KeyGen.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct KeyGen {
    
    @discardableResult
    static func generateNewKeys(tag: String? = nil) throws -> (publickey: SecKey?, privatekey: SecKey?) {
        
        //Step 1
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? String("com.IBM.Holder")
        var privateKeyIdentifier = bundleIdentifier + String(".private")
        var publicKeyIdentifier = bundleIdentifier + String(".public")
        
        if let tag = tag, !tag.isEmpty {
            privateKeyIdentifier = privateKeyIdentifier + String(".") + tag
            publicKeyIdentifier = publicKeyIdentifier + String(".") + tag
        }
        
        let privateKeyTag = privateKeyIdentifier.data(using: .utf8)!
        let publicKeyTag = publicKeyIdentifier.data(using: .utf8)!
        
        let privateKeyParams: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecReturnData as String: true,
            kSecAttrApplicationTag as String: privateKeyTag]
        
        let publicKeyParams: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecReturnData as String: true,
            kSecAttrApplicationTag as String: publicKeyTag]
        
        //Step 2
        let attributes = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPublicKeyAttrs as String: publicKeyParams,
            kSecPrivateKeyAttrs as String: privateKeyParams] as CFDictionary
        
        
        //Step 3
        //Variables to store both the public and private keys.
        var publicKeySec, privateKeySec: SecKey?
        //Second thing is to call the SecKeyGeneratePair API to generate the public and private keys using the created attributes dictionary.
        //Generating both the public and private keys via the SecGeneratePair APIs.
        
        let status = SecKeyGeneratePair(attributes, &publicKeySec, &privateKeySec)
        
        if status == noErr {
            return (publicKeySec, privateKeySec)
        } else {
            let message = SecCopyErrorMessageString(status, nil)
            let errorMessage = (message != nil) ? message! as String : String()
            let error = NSError(domain: errorMessage, code: Int(status), userInfo: nil)
            throw error
        }
    }
    
    static func getCryptographicKey(for privateKey: String) throws -> SecKey? {
        
        let privateKeyParams: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecReturnData as String: true]
        
        let attributes = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecPrivateKeyAttrs as String: privateKeyParams] as CFDictionary
        
        guard let encodedPrivateKeyData = Data(base64Encoded: privateKey) else {
            let encodeError = NSError(domain: "KeyGen PrivateKeyData encoding error", code: 0, userInfo: nil)
            throw encodeError
        }
        
        var keyError: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(encodedPrivateKeyData as CFData, attributes, &keyError) else {
            let encodeError = NSError(domain: keyError.debugDescription, code: 0, userInfo: nil)
            keyError?.release()
            throw encodeError
        }
        
        keyError?.release()
        
        return key
    }
    
    static func decodeKeyToString(_ key: SecKey) throws -> String? {
        do {
            let data = try KeyGen.decodeKeyToData(key)
            return data?.base64EncodedString()
        } catch {
            throw error
        }
    }
    
    static func decodeKeyToData(_ key: SecKey) throws -> Data? {
        var error: Unmanaged<CFError>?
        
        let keySecData = SecKeyCopyExternalRepresentation(key, &error)
        if let err = error as? Error {
            error?.release()
            throw err
        }
        
        return keySecData as Data?
    }
}
