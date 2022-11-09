//
//  Field.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Field {
    //From Credential
    var path: String
    var value: Any?
    var obfuscated: Bool?

    //From Schema
    var type: String?
    var visible: Bool?
    var description: String?
    var format: String?
    var options: [Any]? //enum field type from the schema
    var displayValue: [String: String]?
    var order: Int?

    ///Derived Data
    var parentKey: String? {
        var components = path.components(separatedBy: ".")
        
        if components.count > 1 {
            components = components.dropLast()
            
            while let key = components.last {
                if Int(key) != nil {
                    components = components.dropLast()
                } else {
                    return key
                }
            }
        }
            
        return nil
    }
    
    var localizedPath: String? {
        let defaultLanguageCode = "en"
        if let languageCode = Locale.current.languageCode,
           let localizedValue = displayValue?[languageCode] ?? displayValue?[defaultLanguageCode] {
            return localizedValue
        }
        
        let pathArray = path.components(separatedBy: ".")
        if !(pathArray.isEmpty) {
            return pathArray.last?.snakeCased()?.capitalized
        }
           
        return path.snakeCased()?.capitalized
    }
    
    func getDeobfuscatedVaule(for credential: Credential?) -> String? {
        guard let obfuscation = credential?.obfuscation else { return nil }
        
        guard let requiredObfuscation = obfuscation.filter({ $0.path == path }).first else { return nil }

        return requiredObfuscation.val
    }

}
