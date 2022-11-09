//
//  ResultViewController+TableView.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit

extension ResultViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = (specificationConfiguration != nil) ? 3 : 2
        
        if metricsStatus == .Verified {
            numberOfSections = numberOfSections + 1
        }
        
        if !(displayFields.isEmpty) {
            numberOfSections = numberOfSections + 1
        }
        
        return numberOfSections
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return String("result.credentialSpec".localized)
        }
        
        if (specificationConfiguration != nil) {
            if section == 2 {
                return String("result.credentialType".localized)
            } else if section == 3 {
                return String("result.issuer".localized)
            } else if !displayFields.isEmpty && section == 4 {
                return String("result.credentialDetails".localized)
            }
        } else {
            if section == 2 {
                return String("result.issuer".localized)
            } else if !displayFields.isEmpty && section == 3 {
                return String("result.credentialDetails".localized)
            }
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 || section == 1 || section == 2 {
            return 1
        }
        
        if (specificationConfiguration != nil) {
            if section == 3 {
                return 1
            } else if !displayFields.isEmpty && section == 4 {
                return displayFields.count
            }
        } else {
            if !displayFields.isEmpty && section == 3 {
                return displayFields.count
            }
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let credentialResultCell = tableView.dequeueReusableCell(withIdentifier: "CredentialResultTableViewCell", for: indexPath)
            
            let resultImageView = credentialResultCell.viewWithTag(1) as? UIImageView
            resultImageView?.image = resultImage
            //resultImageView?.tintColor = resultTintColor
            credentialResultCell.backgroundColor = resultTintColor
            
            let resultTitleLabel = credentialResultCell.viewWithTag(2) as? UILabel
            resultTitleLabel?.text =  resultTitle
            
            return credentialResultCell
        } else if indexPath.section == 1 {
            let credentialTypeCell = tableView.dequeueReusableCell(withIdentifier: "CredentialTypeTableViewCell", for: indexPath)
            
            var typeValue = specificationConfiguration?.credentialSpecDisplayValue ?? verifiableObject?.type.displayValue ?? type.displayValue
            if type != verifiableObject?.type {
                typeValue = typeValue + String(" (Unknown)")
            }
            credentialTypeCell.textLabel?.text = typeValue
            
            return credentialTypeCell
        } else if (specificationConfiguration != nil) && indexPath.section == 2 {
            let issuerDetailsCell = tableView.dequeueReusableCell(withIdentifier: "IssuerDetailsTableViewCell", for: indexPath)
            
            issuerDetailsCell.accessoryView = nil
            
            issuerDetailsCell.textLabel?.text = specificationConfiguration?.credentialCategoryDisplayValue ?? specificationConfiguration?.credentialCategory
            
            issuerDetailsCell.detailTextLabel?.textColor = .secondaryLabel
            issuerDetailsCell.detailTextLabel?.text = specificationConfiguration?.specificationConfigurationDescription
            
            return issuerDetailsCell
        } else if ((specificationConfiguration != nil) && indexPath.section == 3) || ((specificationConfiguration == nil) && indexPath.section == 2) {
            let issuerDetailsCell = tableView.dequeueReusableCell(withIdentifier: "IssuerDetailsTableViewCell", for: indexPath)
            
            if fetchingIssuerDetails {
                let activityIndicator = UIActivityIndicatorView(style: .medium)
                activityIndicator.startAnimating()
                issuerDetailsCell.accessoryView = activityIndicator
                
                issuerDetailsCell.textLabel?.text = String("result.checkingIssuer".localized)
            } else {
                issuerDetailsCell.accessoryView = nil
                
                if let issuerDetails = issuerDetails {
                    issuerDetailsCell.textLabel?.text = issuerDetails
                    
                    issuerDetailsCell.detailTextLabel?.textColor = .systemGreen
                    issuerDetailsCell.detailTextLabel?.text = String("result.issuerRecognized".localized)
                } else {
                    issuerDetailsCell.textLabel?.text = String("result.notProvided".localized)
                    
                    issuerDetailsCell.detailTextLabel?.textColor = .systemOrange
                    issuerDetailsCell.detailTextLabel?.text = String("result.issuerNotRecognized".localized)
                }
            }
            
            return issuerDetailsCell
        } else if ((specificationConfiguration != nil) && indexPath.section == 4) || ((specificationConfiguration == nil) && indexPath.section == 3) {
            let displayFieldCell = tableView.dequeueReusableCell(withIdentifier: "DisplayFieldTableViewCell", for: indexPath)
            
            let displayField = displayFields[indexPath.row]
            
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
                
                let derivedValue = last ?? displayField.field
                displayValue = derivedValue.snakeCased()?.capitalized ?? derivedValue
            }
            
            let textLabel = displayFieldCell.viewWithTag(1) as? UILabel
            textLabel?.text = displayValue
            
            let detailTextLabel = displayFieldCell.viewWithTag(2) as? UILabel
            
            if displayField.isObfuscated {
                let obfuscationIndicatorImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
                displayFieldCell.accessoryType = .detailButton
                displayFieldCell.accessoryView = obfuscationIndicatorImageView

                if let obfuscation = displayField.obfuscation, let val = obfuscation.val {
                    detailTextLabel?.text = val
                    
                    obfuscationIndicatorImageView.image = UIImage(systemName: "lock.open.fill")
                    displayFieldCell.tintColor = .systemBlue
                    detailTextLabel?.textColor = .systemBlue
                } else {
                    detailTextLabel?.text = String("Not Shared")
                    
                    obfuscationIndicatorImageView.image = UIImage(systemName: "lock.fill")
                    displayFieldCell.tintColor = .systemRed
                    detailTextLabel?.textColor = .systemRed
                }
            } else {
                let value = displayField.value ?? String("-")
                detailTextLabel?.text = value
              
                displayFieldCell.accessoryType = .none
                displayFieldCell.accessoryView = nil
            }
            
            return displayFieldCell
        }
        
        return UITableViewCell()
    }
    
}
