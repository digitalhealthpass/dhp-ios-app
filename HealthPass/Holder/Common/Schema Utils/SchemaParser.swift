//
//  SchemaParser.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

enum SchemaParserKey: String {
    case visible = "visible"
    case properties = "properties"
    
    case items = "items"
    case type = "type"
    case description = "description"
    case format = "format"
    case options = "enum"
    case displayValue = "displayValue"
    case order = "order"
    
}

class SchemaParser {
    
    private func getAllFields(for subject: [String: Any], at path: String = "") -> [Field] {
        var allFields = [Field]()
        
        let currentPath = path.isEmpty ? path : (path + ".")
        
        for (key, _) in subject {
            if let nested = subject[key] as? [String: Any] {
                let dictionaryFields = getAllFields(for: nested, at: currentPath + key)
                allFields.append(contentsOf: dictionaryFields)
            } else if let nested = subject[key] as? [[String: Any]] {
                let subPath = currentPath + key + "."
                for (index, subObject) in nested.enumerated() {
                    let arrayFields = getAllFields(for: subObject, at: subPath + String(index))
                    allFields.append(contentsOf: arrayFields)
                }
            } else {
                let path = currentPath + key
                let value = subject[key]
                let obfuscated = isObfuscated(value: value)
                
                let field = Field(path: path,
                                  value: value,
                                  obfuscated: obfuscated)
                
                allFields.append(field)
            }
        }
        
        return allFields
    }
    
    
    private func getPropertyField(from properties: [String: Any], at paths: [String], for field: Field) -> Field? {
        let fieldPath = field.path
        let fieldValue = field.value
        let fieldObfuscated = field.obfuscated
        
        var fieldVisibility: Bool?
        var fieldDescription: String?
        var fieldFormat: String?
        var fieldOptions: [Any]?
        var fieldDisplayValue: [String: String]?
        var fieldOrder: Int?
        
        var fieldType: String?
        
        if let key = paths.first, let schemaField = properties[key] as? [String: Any] {
            if paths.count != 1, let processedField = getSchemaField(from: schemaField, at: Array(paths.dropFirst()), for: field) {
                return processedField
            } else if paths.count == 1 {
                fieldVisibility = schemaField[SchemaParserKey.visible.rawValue] as? Bool
                fieldDescription = schemaField[SchemaParserKey.description.rawValue] as? String
                fieldFormat = schemaField[SchemaParserKey.format.rawValue] as? String
                fieldOptions = schemaField[SchemaParserKey.options.rawValue] as? [Any]
                fieldDisplayValue = schemaField[SchemaParserKey.displayValue.rawValue] as? [String: String]
                fieldOrder = schemaField[SchemaParserKey.order.rawValue] as? Int
                
                fieldType = schemaField[SchemaParserKey.type.rawValue] as? String
            }
        }
        
        if fieldValue is [Any] {
            fieldType = String("array")
        } else if fieldValue is [String: Any] {
            fieldType = String("dictionary")
        } else {
            fieldType = String("any")
        }
        
        let value = String(describing: fieldValue ?? "")
        let types: NSTextCheckingResult.CheckingType = [.date]
        if let detector = try? NSDataDetector(types: types.rawValue) {
            let range = NSMakeRange(0, value.count)
            let matches = detector.matches(in: value, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: range)
            
            if !(matches.isEmpty) {
                if Date().isOnlyDate(dateString: value) {
                    fieldType = String("date")
                } else if Date().isOnlyTime(timeString: value) {
                    fieldType = String("time")
                } else {
                    fieldType = String("date-time")
                }
            }
        }
        
        return Field(path: fieldPath,
                     value: fieldValue,
                     obfuscated: fieldObfuscated,
                     type: fieldType,
                     visible: fieldVisibility,
                     description: fieldDescription,
                     format: fieldFormat,
                     options: fieldOptions,
                     displayValue: fieldDisplayValue,
                     order: fieldOrder)
    }
    
    private func getSchemaField(from schema: [String: Any], at paths: [String], for field: Field) -> Field? {
        if let nested = schema[SchemaParserKey.items.rawValue] as? [String: Any],
           let searchedField = getSchemaField(from: nested, at: paths, for: field) {
            return searchedField
        }
        
        if let properties = schema[SchemaParserKey.properties.rawValue] as? [String: Any],
           let searchedField = getPropertyField(from: properties, at: paths, for: field) {
            return searchedField
        }
        
        let candidatesToSearchIn: [String] = ["oneOf", "anyOf", "allOf", "not"]
        
        for candidate in candidatesToSearchIn {
            if let nested = schema[candidate] as? [[String: Any]] {
                for subSchema in nested {
                    if let searchedField = getSchemaField(from: subSchema, at: paths, for: field) {
                        return searchedField
                    }
                }
            }
        }
        
        return nil
    }
    
    func getVisibleFields(for subject: [String: Any], and schema: [String: Any]) -> [Field] {
        var visibleFields = [Field]()
        let allCredentialFields = getAllFields(for: subject)
        
        allCredentialFields.forEach { field in
            if let processedField = getSchemaField(from: schema, at: [field.path], for: field) { //top level
                visibleFields.append(processedField)
            } else {
                var paths = field.path.components(separatedBy: ".")
                paths = paths.filter { !isSerialNumber(serial: $0) }
                
                if let processedField = getSchemaField(from: schema, at: paths, for: field) {
                    visibleFields.append(processedField)
                } else {
                    visibleFields.append(field)
                    print("Warning, not processed: \(field)")
                }
            }
        }
        
        return visibleFields
    }
    
    func isObfuscated(value: Any?) -> Bool? {
        guard let _ = value else {
            return nil
        }
        
        guard let obfuscatedString = value as? String else {
            // only string value can represent obfuscated values
            return false
        }
        
        let range = NSRange(location: 0, length: obfuscatedString.utf16.count)
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9_-]{42,43}$")
        return regex.firstMatch(in: obfuscatedString, options: [], range: range) != nil
    }
    
    func isSerialNumber(serial: String) -> Bool {
        let serialComponent = Int(serial)
        return serialComponent != nil
    }
}
