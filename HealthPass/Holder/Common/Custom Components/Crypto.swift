//
//  Crypto.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import CryptoKit
import CommonCrypto

class Crypto {
    
    enum Cipher {
        case AES, ChaChaPoly
    }
    
    public func encrypt(for dictionary: [String: Any],
                        with cipher: Cipher = .AES,
                        completion: ((_ combined: Data?, _ saltData: Data?, _ succes: Bool, _ statusMessage: String) -> Void)) {
        // Get string from the dictionary
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: JSONSerialization.WritingOptions()) as Data else {
            let statusMessage = "crypto.jsonFailed".localized
            completion(nil, nil, false, statusMessage)
            return
        }
        
        guard let string = String(data: jsonData, encoding: String.Encoding.utf8) else {
            let statusMessage = "crypto.stringEncodingFailed".localized
            completion(nil, nil, false, statusMessage)
            return
        }
        
        Crypto().encrypt(for: string, completion: completion)
    }
    
    public func encrypt(for string: String,
                        with cipher: Cipher = .AES,
                        completion: ((_ combined: Data?, _ saltData: Data?, _ succes: Bool, _ statusMessage: String) -> Void)) {
        // Get data from the string
        guard let data = string.data(using: String.Encoding.utf8) else {
            let statusMessage = "crypto.dataEncodingFailed".localized
            completion(nil, nil, false, statusMessage)
            return
        }
        
        Crypto().encrypt(for: data, completion: completion)
    }
    
    public func encrypt(for data: Data,
                        with cipher: Cipher = .AES,
                        completion: ((_ combined: Data?, _ saltData: Data?, _ succes: Bool, _ statusMessage: String) -> Void)) {
        
        let symmetricKey = SymmetricKey(size: .bits256)
        let saltData = symmetricKey.withUnsafeBytes { Data($0) }
        
        if cipher == .ChaChaPoly {
            guard let sealedBoxData = try? ChaChaPoly.seal(data, using: symmetricKey).combined else {
                let statusMessage = "crypto.sealCreationFailed".localized
                completion(nil, nil, false, statusMessage)
                return
            }
            
            guard let sealedBox = try? ChaChaPoly.SealedBox(combined: sealedBoxData) else {
                let statusMessage = "crypto.sealBoxCreationFailed".localized
                completion(nil, nil, false, statusMessage)
                return
            }
            
            let statusMessage = "crypto.chachaPolySuccess".localized
            completion(sealedBox.combined, saltData, true, statusMessage)
            return
        } else {
            guard let encryptedData = try? AES.GCM.seal(data, using: symmetricKey) else {
                let statusMessage = "crypto.aesSealFailed".localized
                completion(nil, nil, false, statusMessage)
                return
            }
            
            guard let sealedBox = try? AES.GCM.SealedBox(nonce: encryptedData.nonce, ciphertext: encryptedData.ciphertext, tag: encryptedData.tag) else {
                let statusMessage = "crypto.aesSealBoxFailed".localized
                completion(nil, nil, false, statusMessage)
                return
            }
            
            let statusMessage = "crypto.aesSuccess".localized
            completion(sealedBox.combined, saltData, true, statusMessage)
            return
        }
    }
}

extension Crypto {
    
    public func decrypt(combined: Data,
                        saltData: Data,
                        with cipher: Cipher = .AES,
                        completion: ((_ decryptedData: Data?, _ succes: Bool, _ statusMessage: String) -> Void)) {
        
        let symmetricKey = SymmetricKey(data: saltData)
        
        if cipher == .ChaChaPoly {
            guard let sealedBox = try? ChaChaPoly.SealedBox(combined: combined) else {
                let statusMessage = "crypto.dec.chaSealCreationFailed".localized
                completion(nil, false, statusMessage)
                return
            }
            
            guard let decryptedData = try? ChaChaPoly.open(sealedBox, using: symmetricKey) else {
                let statusMessage = "cryoto.dec.chaSealBoxFailed".localized
                completion(nil, false, statusMessage)
                return
            }
            
            let statusMessage = "crypto.dec.chaSuccess".localized
            completion(decryptedData, true, statusMessage)
            return
        } else {
            print("-- AES --")
            guard let sealedBox = try? AES.GCM.SealedBox(combined: combined) else {
                let statusMessage = "crypto.dec.aesSealCreationFailed".localized
                completion(nil, false, statusMessage)
                return
            }
            
            guard let decryptedData = try? AES.GCM.open(sealedBox, using: symmetricKey) else {
                let statusMessage = "crypto.dec.aesSealBoxFailed".localized
                completion(nil, false, statusMessage)
                return
            }
            
            let statusMessage = "crypto.dec.aesSuccess".localized
            completion(decryptedData, true, statusMessage)
            return
        }
    }
}

extension Crypto {
    
    public func hash(for dictionary: [String: Any],
                     completion: ((_ hash: Int?, _ succes: Bool, _ statusMessage: String) -> Void)) {
        // Get string from the dictionary
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: JSONSerialization.WritingOptions()) as Data else {
            let statusMessage = "crypto.hash.jsonEncFailed".localized
            completion(nil, false, statusMessage)
            return
        }
        
        guard let string = String(data: jsonData, encoding: String.Encoding.utf8) else {
            let statusMessage = "crypto.hash.stringEncFailed".localized
            completion(nil, false, statusMessage)
            return
        }
        
        Crypto().hash(for: string, completion: completion)
    }
    
    public func hash(for string: String,
                     completion: ((_ hash: Int?, _ succes: Bool, _ statusMessage: String) -> Void)) {
        // Get data from the string
        guard let data = string.data(using: String.Encoding.utf8) else {
            let statusMessage = "crypto.hash.dataEncFailed".localized
            completion(nil, false, statusMessage)
            return
        }
        
        return Crypto().hash(for: data, completion: completion)
    }
    
    public func hash(for data: Data,
                     completion: ((_ hash: Int?, _ succes: Bool, _ statusMessage: String) -> Void)) {
        let receivedDataDigest = SHA256.hash(data: data)
        let hashValue = receivedDataDigest.hashValue
        
        let statusMessage = "crypto.hash.success".localized
        completion(hashValue, true, statusMessage)
        return
    }
}

struct AESCrypto {
    
    enum Error: Swift.Error {
        case encryptionError(status: CCCryptorStatus)
        case decryptionError(status: CCCryptorStatus)
        case keyDerivationError(status: CCCryptorStatus)
    }
    
    func encrypt(data: Data, key: Data, iv: Data, padding: Bool = false) throws -> Data {
        let outputLength = data.count + kCCBlockSizeAES128
        var outputBuffer = Array<UInt8>(repeating: 0, count: outputLength)
        var numBytesEncrypted = 0
        
        let status = CCCrypt(CCOperation(kCCEncrypt),
                             CCAlgorithm(kCCAlgorithmAES),
                             CCOptions(kCCOptionPKCS7Padding),
                             Array(key),
                             kCCKeySizeAES256,
                             Array(iv),
                             Array(data),
                             data.count,
                             &outputBuffer,
                             outputLength,
                             &numBytesEncrypted)
       
        guard status == kCCSuccess else {
            throw Error.encryptionError(status: status)
        }
        
        var outputBytes = outputBuffer.prefix(numBytesEncrypted)
        
        if padding {
            outputBytes = iv + outputBuffer.prefix(numBytesEncrypted)
        }
        
        return Data(outputBytes)
    }
    
    func decrypt(data cipherData: Data, key: Data, iv: Data) throws -> Data {
        let cipherTextLength = cipherData.count
        // Output buffer
        var outputBuffer = Array<UInt8>(repeating: 0, count: cipherTextLength)
        var numBytesDecrypted = 0
        let status = CCCrypt(CCOperation(kCCDecrypt),
                             CCAlgorithm(kCCAlgorithmAES),
                             CCOptions(kCCOptionPKCS7Padding),
                             Array(key),
                             kCCKeySizeAES256,
                             Array(iv),
                             Array(cipherData),
                             cipherTextLength,
                             &outputBuffer,
                             cipherTextLength,
                             &numBytesDecrypted)
        
        guard status == kCCSuccess else {
            throw Error.decryptionError(status: status)
        }
        
        return Data(outputBuffer.prefix(numBytesDecrypted))
    }
    
    func derivateKey(passphrase: String, salt: String) throws -> Data {
        let rounds = UInt32(45_000)
        var outputBytes = Array<UInt8>(repeating: 0,
                                       count: kCCKeySizeAES256)
        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            passphrase,
            passphrase.utf8.count,
            salt,
            salt.utf8.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),
            rounds,
            &outputBytes,
            kCCKeySizeAES256)
        
        guard status == kCCSuccess else {
            throw Error.keyDerivationError(status: status)
        }
        return Data(outputBytes)
    }
}
