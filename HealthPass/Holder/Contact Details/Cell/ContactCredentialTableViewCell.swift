//
//  ContactCredentialTableViewCell.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class ContactCredentialTableViewCell: UITableViewCell {
    
    @IBOutlet weak var credentialSchemaNameLabel: UILabel?
    
    @IBOutlet weak var credentialTypeLabel: UILabel?
    @IBOutlet weak var credentialIssuerNameLabel: UILabel?
    @IBOutlet weak var credentialIssuerImageView: UIImageView?
    
    @IBOutlet weak var credentialDisplayView: GradientView?
    @IBOutlet weak var credentialExpirationLabel: UILabel?
    
    @IBOutlet weak var selectedImageView: UIImageView?
    
    // Credential Download properties
    private let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        credentialTypeLabel?.font = AppFont.headlineScaled
        credentialSchemaNameLabel?.font = AppFont.bodyScaled
        credentialIssuerNameLabel?.font = AppFont.subheadlineScaled
        credentialExpirationLabel?.font = AppFont.footnoteScaled
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        credentialTypeLabel?.adjustsFontSizeToFitWidth = true
        credentialIssuerNameLabel?.adjustsFontSizeToFitWidth = true
        credentialExpirationLabel?.adjustsFontSizeToFitWidth = true
    }
}

extension ContactCredentialTableViewCell {
    
    func defaultCell() {
        credentialSchemaNameLabel?.text = String("Unknown Schema")
        
        credentialTypeLabel?.text = String("Unknown Type")
        credentialIssuerNameLabel?.text = String("Unknown Issuer")
        credentialIssuerImageView = nil
        
        credentialExpirationLabel?.text = nil
        
        selectedImageView?.image = nil
        selectionStyle = .none
        isUserInteractionEnabled = false
    }
    
    func populateCell(with package: Package, isSelected: Bool, enabled: Bool = true, errorMessage: String? = nil) {
        updateCell(package: package)
        updateForContactDetail(package: package)
        updateForCredentialSelect(package: package)
        updateForSelection(isSelected: isSelected, enabled: enabled)
        //updateForUploadComplete(errorMessage: errorMessage)
    }
    
    private func updateCell(package: Package) {
        if package.type == .VC || package.type == .IDHP || package.type == .GHP {
            credentialSchemaNameLabel?.text = package.schema?.name
        } else if package.type == .SHC {
            credentialSchemaNameLabel?.text = package.SHCSchemaName
        } else if package.type == .DCC {
            credentialSchemaNameLabel?.text = package.DCCSchemaName
        }
    }
    
    private func updateForContactDetail(package: Package) {
        if let expiryDate = package.expirationDateValue {
            let expString = package.isExpired ? "Expired" : "Expires"
            credentialExpirationLabel?.text = String(format: "%@: %@", expString, Date.stringForDate(date: expiryDate, dateFormatPattern: .defaultDate))
        } else {
            credentialExpirationLabel?.text = nil
        }
        
        var primaryColor = UIColor.black
        if package.type == .VC || package.type == .IDHP || package.type == .GHP {
            primaryColor = package.credential?.extendedCredentialSubject?.getColor() ?? UIColor.black
        } else if package.type == .SHC {
            primaryColor = package.SHCColor
        } else if package.type == .DCC {
            primaryColor = package.DCCColor
        }
        
        credentialDisplayView?.primaryColor = primaryColor
    }
    
    private func updateForCredentialSelect(package: Package) {
        credentialTypeLabel?.text = package.type.displayValue //credential?.extendedCredentialSubject?.type
        
        if package.type == .VC || package.type == .IDHP || package.type == .GHP {
            credentialIssuerNameLabel?.text = package.issuerMetadata?.metadata?["name"] as? String
            
            if let issuerLogoString = package.issuerMetadata?.metadata?["logo"] as? String,
               let issuerLogoData = Data(base64Encoded: issuerLogoString, options: .ignoreUnknownCharacters),
               let issuerLogoImage = UIImage(data: issuerLogoData) {
                credentialIssuerImageView?.image = issuerLogoImage
            } else {
                credentialIssuerImageView?.image = nil
            }
        } else if package.type == .SHC {
            package.SHCIssuerName.done { value in
                self.credentialIssuerNameLabel?.text = value
            }.catch { _ in }
            
            credentialIssuerImageView?.image = nil
        } else if package.type == .DCC {
            credentialIssuerNameLabel?.text = package.DCCIssuerName
            credentialIssuerImageView?.image = nil
        }
        
    }
    
    private func updateForSelection(isSelected: Bool, enabled: Bool) {
        if enabled {
            selectedImageView?.tintColor = UIColor.systemBlue
            selectedImageView?.image = isSelected ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circlebadge")
        } else {
            selectedImageView?.tintColor = UIColor.systemRed
            selectedImageView?.image = UIImage(systemName: "circle.slash.fill")
        }
        
        selectionStyle = enabled ? .default : .none
        isUserInteractionEnabled = enabled
    }
    
    private func updateForUploadComplete(errorMessage: String?) {
        credentialIssuerNameLabel?.textColor = .secondaryLabel
        if let errorMessage = errorMessage {
            credentialIssuerNameLabel?.text = errorMessage
            credentialIssuerNameLabel?.textColor = .systemRed
        }
    }
}

extension ContactCredentialTableViewCell {
    func populateCell(with credential: Credential) {
        selectionStyle = .none
        isUserInteractionEnabled = false
        
        activityIndicatorView.startAnimating()
        accessoryView = activityIndicatorView
        
        credentialSchemaNameLabel?.text = "contact.credentials.verifying".localized
        
        if let expireDateString = credential.expirationDate {
            let credentialExpired = credential.isExpired
            let expString = credentialExpired ? "Expired" : "Expires"
            let expiryDate = Date.dateFromString(dateString: expireDateString)
            credentialExpirationLabel?.text = String(format: "%@: %@", expString, Date.stringForDate(date: expiryDate, dateFormatPattern: .defaultDate))
        } else {
            credentialExpirationLabel?.text = nil
        }
        
        let primaryColor = credential.extendedCredentialSubject?.getColor() ?? UIColor.black
        credentialDisplayView?.primaryColor = primaryColor
    }
}
