//
//  BufferCompression.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import CryptoKit

class BufferCompression {
    public func compress(for dictionary: [String : Any], to file: String, with password: String?, completion: (_ destinationURL: URL?, _ errorMessage: String?) -> Void) {
        let encodedFileName = String(format: "%@.hpzip", file)
        let tempDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
        
        guard let password = password,
              let passwordData = data256(from: password),
              let jsonData = try? NSKeyedArchiver.archivedData(withRootObject: dictionary, requiringSecureCoding: true),
              let encodedFileURL = tempDirURL.appendingPathComponent(encodedFileName),
              let archive = try? NSKeyedArchiver.archivedData(withRootObject: jsonData, requiringSecureCoding: true),
              let encryptedArchive = try? ChaChaPoly.seal(archive, using: SymmetricKey(data: passwordData)) else {
            completion(nil, "buffer.encodeFailed".localized)
            return
        }
        
        FileManager.default.createFile(atPath: encodedFileURL.path, contents: encryptedArchive.combined, attributes: nil)
        completion(encodedFileURL, nil)
    }
    
    public func decompress(from url: URL, with password: String, completion: (_ unarchiveData: [String : Any]?, _ errorMessage: String?) -> Void) {
        guard let passwordData = data256(from: password),
              let encryptedArchive = FileManager.default.contents(atPath: url.path),
              let sealedBox = try? ChaChaPoly.SealedBox(combined: encryptedArchive),
              let decryptedData = try? ChaChaPoly.open(sealedBox, using: SymmetricKey(data: passwordData)),
              let jsonData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSData.self, from: decryptedData) as Data?,
              let json = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(jsonData) as? [String: Any] else {
            completion(nil, "buffer.decodeFailed".localized)
            return
        }
        
        completion(json, nil)
    }
    
    private func data256(from string: String) -> Data? {
        guard let stringData = string.data(using: .utf8) else { return nil }
        let bufferSize = SymmetricKeySize.bits256.bitCount / 8
        
        if string.utf8.count > bufferSize {
            return stringData[0..<bufferSize]
        } else {
            let paddingSize = bufferSize - stringData.count
            let padding = String(repeating: "\(0)", count: paddingSize)
            guard let paddingData = padding.data(using: .utf8) else { return nil }
            let data = stringData + paddingData
            return data
        }
    }
}
