//
//  CredentialObfuscationFieldCell.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

protocol CredentialObfuscationFieldDelegate: AnyObject {
    func didChangeValue(for field: String, isOn: Bool)
}

class CredentialObfuscationFieldCell: UITableViewCell {
    // MARK: - Outlets
    
    @IBOutlet weak var fieldNameLabel: UILabel!
    @IBOutlet weak var fieldSwitch: UISwitch!
    
    // MARK: - Properties
    
    static let identifier = "CredentialObfuscationFieldCell"
    weak var delegate: CredentialObfuscationFieldDelegate?
    
    // MARK: - Methods
    
    func populate(with fieldName: String, isOn: Bool) {
        fieldKey = fieldName
        fieldNameLabel.text = title(for: fieldName)
        fieldSwitch.isOn = isOn
    }
    
    // MARK: - Actions
    
    @IBAction func toggleFieldSwitch(_ sender: UISwitch) {
        guard let field = fieldKey else { return }
        
        delegate?.didChangeValue(for: field, isOn: fieldSwitch.isOn)
    }
    
    // MARK: - Private Properties
    
    private var fieldKey: String?
    
    // MARK: - Private Methods
    
    private func title(for fieldName: String) -> String {
        return fieldName.split(separator: ".").last?.capitalized ?? fieldName
    }
}
