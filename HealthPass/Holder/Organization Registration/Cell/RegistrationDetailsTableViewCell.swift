//
//  RegistrationDetailsTableViewCell.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class RegistrationDetailsTableViewCell: UITableViewCell {
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel?.font = AppFont.calloutScaled
        valueTextField?.font = AppFont.bodyScaled
        desctiptionLabel?.font = AppFont.footnoteScaled

        containerView?.layer.borderColor = UIColor.systemBlue.cgColor
        valueTextField?.delegate = self
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var desctiptionLabel: UILabel?
    
    @IBOutlet weak var containerView: UIView?
    @IBOutlet weak var valueTextField: UITextField?
    @IBOutlet weak var optionssButton: UIButton?
    
    // MARK: - IBAction

    @IBAction func onOptions(_ sender: Any) {
        if hasDropDown() {
            delegate?.valueSelectList(for: title, and: dictionary, value: value, values: values)
        }
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================

    // MARK: Internal Properties
    
    weak var delegate: RegistrationDetailsDelegate?
    
    // MARK: Internal Methods
    
    func populateCell(title: String, dictionary: [String: Any], value: String?, values: [String]?) {
        defaultCellState()
        
        self.title = title
        self.dictionary = dictionary
        self.value = value
        self.values = values
        
        titleLabel?.text = title.snakeCased()?.capitalized
        desctiptionLabel?.text = dictionary["description"] as? String
        
        if let value = value {
            valueTextField?.text = value
        } else if let values = values {
            valueTextField?.text = values.joined(separator: ", ")
        }
        
        if hasDropDown() {
            valueTextField?.placeholder = "reg.select".localized
            
            optionssButton?.isHidden = false
            optionssButton?.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        } else if canEdit() {
            valueTextField?.placeholder = "reg.enterValue".localized
            if format == "email" {
                valueTextField?.keyboardType = .emailAddress
            } else {
                valueTextField?.keyboardType = .default
            }
        } else {
            optionssButton?.isHidden = false
            optionssButton?.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    private let textDisplayType = "Text"
    private var title: String?
    private var dictionary: [String: Any]?
    private var value: String?
    private var values: [String]?
    
    private var format: String? {
        return dictionary?["format"] as? String
    }

    private var regex: String? {
        return dictionary?["pattern"] as? String
    }
    
    private var displayType: String? {
        return dictionary?["displayType"] as? String
    }
    
    // MARK: Private Methods
    
    private func defaultCellState() {
        titleLabel?.text = nil
        desctiptionLabel?.text = nil
       
        valueTextField?.text = nil
        valueTextField?.placeholder = nil

        optionssButton?.isHidden = true
    }
    
    private func isValidText(_ input: String) -> Bool {
        guard let regex = regex else {
            return true
        }
        
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        let isValidText = predicate.evaluate(with: input)
        return isValidText
    }
    
    private func hasDropDown() -> Bool {
        
        let dropDownItems = ["enum", "items"]
        
        let hasDropDown = dictionary?.keys.contains(where: dropDownItems.contains) ?? false
        return (hasDropDown || title?.lowercased() == "location") //FIXME
    }
    
    private func canEdit() -> Bool {
        let uneditableSections = ["key", "id"]
        guard let title = title?.lowercased() else {
            return false
        }
        
        let canEdit = !(uneditableSections.contains(title))
        return canEdit
    }
}

extension RegistrationDetailsTableViewCell: UITextFieldDelegate {
    
    // ======================================================================
    // === UITextField ======================================================
    // ======================================================================
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if hasDropDown() {
            delegate?.valueSelectList(for: title, and: dictionary, value: value, values: values)
            return false
        }
        
        if !(canEdit()) {
            //Uneditable sections
            return false
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }

    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.count > 1 {
            if let t = title, displayType == textDisplayType {
                delegate?.registrationTextValueUpdated(t, value: string)
            }
            return true
        }
        
        if let text = textField.text, let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            if isValidText(updatedText) {
                if let t = title, displayType == textDisplayType {
                    delegate?.registrationTextValueUpdated(t, value: updatedText)
                }
                return true
            }
            
            return false
        }
        
        return true
    }
    
}
