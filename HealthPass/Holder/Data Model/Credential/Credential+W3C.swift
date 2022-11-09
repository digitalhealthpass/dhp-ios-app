//
//  Credential+W3C.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

extension Credential {
    private static var fileExtension: String { ".w3c" }
    
    func saveAsW3C(with name: String? = nil) -> URL? {
        guard
            let appSupportFolder = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true),
            let name = name ?? self.id
        else {
            return nil
        }
        
        let fileName = name.hasSuffix(Credential.fileExtension) ? name : (name.appending(Credential.fileExtension))
        let pathURL = appSupportFolder.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: pathURL.path) {
            try? FileManager.default.removeItem(atPath: pathURL.path)
        }
        
        let data = rawString?.data(using: .utf8)
        let result = FileManager.default.createFile(atPath: pathURL.path, contents: data, attributes: nil)
        return result ? pathURL : nil
    }
}
