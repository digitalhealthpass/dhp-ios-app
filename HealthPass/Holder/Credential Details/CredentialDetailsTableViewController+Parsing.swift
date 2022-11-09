//
//  CredentialDetailsTableViewController+Parsing.swift
//  Holder
//
//  Created by Gautham Velappan on 12/6/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

//SHC & DCC parsing methods
extension CredentialDetailsTableViewController {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Methods
    
    internal func prepareDisplayFields() -> [DisplayField]? {
        guard let displayFields = getDisplayConfig() else {
            return nil
        }
        
        guard let parserDisplayFields = self.parseDisplayFields(displayFields: displayFields) else {
            return nil
        }
        
        return parserDisplayFields
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods
    
    private func getDisplayConfig() -> [DisplayField]? {
        let fileName: String
        let credentialType: String
        
        if package?.type == .SHC{
            fileName = "display_shc.json"
            credentialType = "SHC"
        } else {
            fileName = "display_dcc.json"
            credentialType = "DCC"
        }
        
        guard let display = readJSONFromFile(fileName: fileName) else {
            return nil
        }
        
        guard let configuration = display["configuration"] as? [String: Any] else {
            return nil
        }
        
        guard let credential = configuration[credentialType] as? [String: Any] else {
            return nil
        }
        
        guard let details = credential["details"] as? [[String: Any]] else {
            return nil
        }
        
        guard let fieldsData = try? JSONSerialization.data(withJSONObject: details, options: .prettyPrinted) else {
            return nil
        }
        
        guard let displayFields = (try? JSONDecoder().decode([DisplayField].self, from: fieldsData)) else {
            return nil
        }
        
        return displayFields
    }
    
    private func parseDisplayFields(displayFields: [DisplayField]) -> [DisplayField]?  {
        var parseDisplayFields = [DisplayField]()
        
        guard let json = package?.verifiableObject?.payload as? [String: Any] else {
            return nil
        }
        
        displayFields.forEach { displayField in
            let path = displayField.field
            
            if let value = self.getValue(at: path, for: json) {
                var requiredDisplayField = displayField
                requiredDisplayField.value = value
                requiredDisplayField.type = String("string")
                
                let types: NSTextCheckingResult.CheckingType = [.date]
                if let detector = try? NSDataDetector(types: types.rawValue) {
                    let range = NSMakeRange(0, value.count)
                    let matches = detector.matches(in: value, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: range)
                    
                    if !(matches.isEmpty) {
                        if Date().isOnlyDate(dateString: value) {
                            requiredDisplayField.type = String("date")
                        } else if Date().isOnlyTime(timeString: value) {
                            requiredDisplayField.type = String("time")
                        } else {
                            requiredDisplayField.type = String("date-time")
                        }
                    }
                }
                
                parseDisplayFields.append(requiredDisplayField)
            }
            
        }
        
        return parseDisplayFields
    }
    
    private func getValue(at path: String, for json: [String: Any]) -> String? {
        var path = path.replacingOccurrences(of: "[", with: ".", options: .literal, range: nil)
        path = path.replacingOccurrences(of: "]", with: "", options: .literal, range: nil)
        
        let keys = path.components(separatedBy: ".")
        var trimmedValue: Any? = json
        
        var value: String?
        keys.forEach { key in
            
            if let index = Int(key) {
                guard let loopingValue = trimmedValue as? [Any], !(loopingValue.isEmpty), loopingValue.count > index else {
                    return
                }
                
                if keys.last == key {
                    let val = loopingValue[index]
                    if let directValue = val as? String {
                        value = directValue
                    } else if let arrayValue = val as? [Any] {
                        let stringArrayValue = arrayValue.compactMap{ String(describing: $0) }
                        value = stringArrayValue.joined(separator: " ")
                    } else if let dictionaryValue = val as? [String: Any], let data = try? JSONSerialization.data(withJSONObject: dictionaryValue, options: [.sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]) as Data {
                        value = String(data: data, encoding: .utf8)
                    } else {
                        value = String(describing: val)
                    }
                }
                
                trimmedValue = loopingValue[index]
            } else {
                let loopingValue: [String: Any]
                
                if let value = trimmedValue as? [String: Any], !(value.isEmpty) {
                    loopingValue = value
                } else if let value = trimmedValue as? [[String: Any]], !(value.isEmpty) {
                    loopingValue = value[0]
                } else {
                    return
                }
                
                if keys.last == key, let val = loopingValue[key] {
                    if let directValue = val as? String {
                        value = directValue
                    } else if let arrayValue = val as? [Any] {
                        let stringArrayValue = arrayValue.compactMap{ String(describing: $0) }
                        value = stringArrayValue.joined(separator: " ")
                    } else if let dictionaryValue = val as? [String: Any], let data = try? JSONSerialization.data(withJSONObject: dictionaryValue, options: [.sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]) as Data {
                        value = String(data: data, encoding: .utf8)
                    } else {
                        value = String(describing: val)
                    }
                }
                
                trimmedValue = loopingValue[key]
            }
        }
        
        return value
    }
    
    private func readJSONFromFile(fileName: String) -> [String: Any]? {
        let components = fileName.components(separatedBy: ".")
        let resource = components.first ?? fileName
        let type = components.last ?? String("json")
        
        if let path = Bundle.main.path(forResource: resource, ofType: type) {
            do {
                let fileUrl = URL(fileURLWithPath: path)
                let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
                return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            } catch {
                return nil
            }
        }
        return nil
    }
    
}

