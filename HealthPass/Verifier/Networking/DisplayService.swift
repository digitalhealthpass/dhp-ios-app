//
//  DisplayService.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire
import VerifiableCredential
import VerificationEngine

typealias CompletionDisplayFieldHandler = (Result<[DisplayField]>) -> Void

//TODO: Replace local data fetch with APIs
class DisplayService: Network {
    
    public func getSupportedTypes() -> [String]? {
        guard let allConfiguration = DataStore.shared.currentVerifierConfiguration?.configuration?.value as? [String: Any] else {
            return nil
        }
        
        let supportedTypes = Array(allConfiguration.keys)
        return supportedTypes
    }
    
    public func getDisplayConfig(for spec: VerifiableCredential.VCType) -> [DisplayField]? {
        
        guard let allConfiguration = DataStore.shared.currentVerifierConfiguration?.configuration?.value as? [String: Any] else {
            return nil
        }
        
        guard let configuration = allConfiguration[spec.keyId] as? [String: Any] else {
            return nil
        }
        
        guard let displayConfigurations = configuration["display"] as? [[String: Any]], let displayConfiguration = displayConfigurations.first else {
            return nil
        }
        
        guard let fields = displayConfiguration["fields"] as? [[String: Any]] else {
            return nil
        }
        
        let displayFields = fields.compactMap ({ return DisplayField(field: $0["field"] as? String ?? String(),
                                                                     displayValue: $0["displayValue"] as? [String: String] ?? [String: String]()) })
        
        return displayFields
        
    }
    
    public func getDisplayConfig(for specificationConfiguration: SpecificationConfiguration?) -> [DisplayField]? {
        
        guard let display = specificationConfiguration?.display else {
            return nil
        }
        
        let fields = display.compactMap ({ $0.fields }).flatMap({ $0 })
        
        let displayFields = fields.compactMap { return DisplayField(field: $0.field, displayValue: $0.displayValue ) }
        
        return displayFields
        
    }
    
    public func getAllDisplayFields(for verifiableObject: VerifiableObject?) -> [DisplayField]? {
        
        guard let verifiableObject = verifiableObject else {
            return nil
        }
        
        switch verifiableObject.type {
        case .VC, .GHP, .IDHP:
            guard let credentialSubject = verifiableObject.credential?.credentialSubject else {
                return nil
            }
            
            let fields = self.parseFields(for: credentialSubject)
            return fields
            
        case .SHC, .DCC:
            guard let payload = verifiableObject.payload as? [String: Any] else {
                return nil
            }
            
            let fields = self.parseFields(for: payload)
            return fields
            
        default:
            return nil
        }
        
    }
    
    private func parseFields(for subject: [String: Any], at path: String = "") -> [DisplayField] {
        var allFields = [DisplayField]()
        
        let currentPath = path.isEmpty ? path : (path + ".")
        
        for (key, _) in subject {
            if let nested = subject[key] as? [String: Any] {
                let dictionaryFields = parseFields(for: nested, at: currentPath + key)
                allFields.append(contentsOf: dictionaryFields)
            } else if let nested = subject[key] as? [[String: Any]] {
                let subPath = currentPath + key + "."
                for (index, subObject) in nested.enumerated() {
                    let arrayFields = parseFields(for: subObject, at: subPath + String(index))
                    allFields.append(contentsOf: arrayFields)
                }
            } else {
                let path = currentPath + key
                
                var value: String?
                if let val = subject[key] {
                    value = val as? String ?? String(describing: val)
                }
                
                let field = DisplayField(field: path,
                                         displayValue: [: ],
                                         value: value,
                                         type: nil)
                
                allFields.append(field)
            }
        }
        
        return allFields.sorted(by: { $0.field < $1.field })
    }
    
    public func scanObfuscation(for fields: [DisplayField], with verifiableObject: VerifiableObject?) -> [DisplayField] {
        var scannedFields = [DisplayField]()
        fields.forEach { field in
            var currentField = field
            
            if let filteredObfuscation = verifiableObject?.credential?.obfuscation?.filter({ $0.path == currentField.field }), !(filteredObfuscation.isEmpty) {
                currentField.isObfuscated = true
                currentField.obfuscation = filteredObfuscation.first
            } else {
                currentField.isObfuscated = isObfuscated(value: field.value)
            }
            
            scannedFields.append(currentField)
        }
        
        return scannedFields
    }
    
    private func isObfuscated(value: Any?) -> Bool {
        guard let _ = value else {
            return false
        }
        
        guard let obfuscatedString = value as? String else {
            // only string value can represent obfuscated values
            return false
        }
        
        let range = NSRange(location: 0, length: obfuscatedString.utf16.count)
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9_-]{42,43}$")
        return regex.firstMatch(in: obfuscatedString, options: [], range: range) != nil
    }
    
    
}
