//
//  CredentialInfoTableViewCell.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

struct CredentialInfoTableViewCellModel {
    var title: String
    var value: String?
    
    var success: Bool?
    var processed: Bool?
}

class CredentialInfoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var valueLabel: UILabel?
    
    var obfuscationIndicatorImageView: UIImageView?
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel?.font = AppFont.bodyScaled
        valueLabel?.font = AppFont.bodyScaled
        
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        obfuscationIndicatorImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        obfuscationIndicatorImageView?.image = UIImage(systemName: "lock.open.fill")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel?.text = nil
        valueLabel?.text = nil
        accessoryView = nil
    }
    
    func populateCell(with model: CredentialInfoTableViewCellModel) {
        titleLabel?.text = model.title
        valueLabel?.text = model.value
        
        if let processed = model.processed, !processed {
            accessoryView = activityIndicator
            accessoryType = .none
            activityIndicator.startAnimating()
        } else {
            if let success = model.success {
                let verifiedImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
                verifiedImageView.image = success ? UIImage(systemName: "checkmark.seal.fill") : UIImage(systemName: "xmark.seal.fill")
                verifiedImageView.tintColor = success ? .systemGreen : .systemRed
                accessoryView = verifiedImageView
            } else {
                accessoryView = nil
            }
            activityIndicator.stopAnimating()
        }
    }
    
    func populateCell(for field: Field?, with package: Package) {
        titleLabel?.text = field?.localizedPath
        valueLabel?.text = "-"

        let isObfuscated = field?.obfuscated ?? false
        accessoryType = isObfuscated ? .detailButton : .none
        accessoryView = isObfuscated ? obfuscationIndicatorImageView : nil

        valueLabel?.textColor = isObfuscated ? valueLabel?.tintColor : UIColor.secondaryLabel
        
        guard let value = field?.value else {
            return
        }

        if let array = value as? [Any] {
            let stringArray = array.compactMap { String(describing: $0) }
            let stringRepresentation = stringArray.joined(separator: "\n")
            valueLabel?.text = stringRepresentation
        } else if let value = value as? String {
            if field?.type == String("date") {
                let date = Date.dateFromString(dateString: value)
                valueLabel?.text = Date.stringForDate(date: date, dateFormatPattern: .fullDate)
            } else if field?.type == String("time") {
                let date = Date.dateFromString(dateString: value)
                valueLabel?.text = Date.stringForDate(date: date, dateFormatPattern: .defaultTime)
            } else if field?.type == String("date-time") {
                let date = Date.dateFromString(dateString: value)
                valueLabel?.text = Date.stringForDate(date: date, dateFormatPattern: .fullDateTime)
            } else {
                valueLabel?.text = isObfuscated ? field?.getDeobfuscatedVaule(for: package.credential) : value
            }
        } else {
            valueLabel?.text = isObfuscated ? field?.getDeobfuscatedVaule(for: package.credential) : String(describing: value)
        }
    }
    
    func populateCell(for displayField: DisplayField) {
        var displayValue = String()
        
        let defaultLanguageCode = "en"
        if let locale = Locale.current.languageCode,
           let localeDisplayValue = displayField.displayValue[locale] ?? displayField.displayValue[defaultLanguageCode] {
            displayValue = localeDisplayValue
        } else {
            let field = displayField.field
            var sepratedField = field.components(separatedBy: ".")
            var last = sepratedField.last
            
            if let _ = last, let _ = Int(last!) {
                sepratedField = sepratedField.dropLast()
                last = sepratedField.last
            }
            
            displayValue = last ?? displayField.field
        }
        
        titleLabel?.text = displayValue
        valueLabel?.text = String("-")
        
        guard let value = displayField.value else {
            return
        }
        
        if displayField.type == String("string") {
            let key = value
            if let valueMapperKey = displayField.valueMapper, let value = self.lookupValue(for: key, with: valueMapperKey) {
                valueLabel?.text = value
            } else {
                valueLabel?.text = key
            }
        } else if displayField.type == String("date") {
            let date = Date.dateFromString(dateString: value)
            valueLabel?.text = Date.stringForDate(date: date, dateFormatPattern: .fullDate)
        } else if displayField.type == String("time") {
            let date = Date.dateFromString(dateString: value)
            valueLabel?.text = Date.stringForDate(date: date, dateFormatPattern: .defaultTime)
        } else if displayField.type == String("date-time") {
            let date = Date.dateFromString(dateString: value)
            valueLabel?.text = Date.stringForDate(date: date, dateFormatPattern: .fullDateTime)
        }
    }
    
    private func lookupValue(for key: String, with valueMapperKey: String) -> String? {
        guard let valueMapper = readJSONFromFile(fileName: "value-mapper.json") else {
            return nil
        }
        
        guard let map = valueMapper[valueMapperKey] as? [String: Any] else {
            return nil
        }
        
        guard let value = map[key] as? String else {
            return nil
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
