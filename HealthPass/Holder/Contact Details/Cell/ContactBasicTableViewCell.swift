//
//  ContactBasicTableViewCell.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import MessageUI

class ContactBasicTableViewCell: UITableViewCell {
    
    @IBOutlet weak var contactIssuerImageView: UIImageView!
    @IBOutlet weak var contactIssuerLabel: UILabel!
    @IBOutlet weak var connectionLabel: UILabel!
    
    @IBOutlet weak var contactCallView: UIView!
    @IBOutlet weak var contactCallImageView: UIImageView!
    @IBOutlet weak var contactCallLabel: UILabel!
    
    @IBOutlet weak var contactEmailView: UIView!
    @IBOutlet weak var contactEmailImageView: UIImageView!
    @IBOutlet weak var contactEmailLabel: UILabel!
    
    @IBOutlet weak var contactWebsiteView: UIView!
    @IBOutlet weak var contactWebsiteImageView: UIImageView!
    @IBOutlet weak var contactWebsiteLabel: UILabel!
    
    var piiController: PiiControllers?
    
    weak var delegate : ContactDetailsTableViewControllerDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        separatorInset = UIEdgeInsets.init(top: 0, left: UIScreen.main.bounds.width, bottom: 0, right: 0)
        
        let contactCallGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onContactCall(_:)))
        contactCallView?.addGestureRecognizer(contactCallGestureRecognizer)
        
        let contactEmailGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onContactEmail(_:)))
        contactEmailView?.addGestureRecognizer(contactEmailGestureRecognizer)
        
        let contactWebsitwGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onContactWebsite(_:)))
        contactWebsiteView?.addGestureRecognizer(contactWebsitwGestureRecognizer)
        
        contactIssuerImageView.isAccessibilityElement = true
        contactIssuerImageView.accessibilityTraits = .image
        contactIssuerImageView.isUserInteractionEnabled = true
        contactIssuerImageView.accessibilityValue = .none
        
        contactIssuerLabel.isAccessibilityElement = true
        contactIssuerLabel.accessibilityTraits = .staticText
        contactIssuerLabel.isUserInteractionEnabled = true
        contactIssuerLabel.accessibilityValue = .none
        
        connectionLabel.isAccessibilityElement = true
        connectionLabel.accessibilityTraits = .staticText
        connectionLabel.isUserInteractionEnabled = true
        connectionLabel.accessibilityValue = .none
    }
    
    func populateCell(with contact: Contact) {
        contactIssuerLabel?.text = String("-")
        contactIssuerImageView.image = nil
        
        contactCallView.isAccessibilityElement = true
        contactCallView.accessibilityTraits = .button
        contactCallView.isUserInteractionEnabled = false
        contactCallView.accessibilityValue = "accessibility.dimmed".localized
        contactCallImageView.tintColor = UIColor.systemGray
        contactCallLabel.textColor = UIColor.systemGray
        
        contactEmailView.isAccessibilityElement = true
        contactEmailView.accessibilityTraits = .button
        contactEmailView.isUserInteractionEnabled = false
        contactEmailView.accessibilityValue = "accessibility.dimmed".localized
        contactEmailImageView.tintColor = UIColor.systemGray
        contactEmailLabel.textColor = UIColor.systemGray
        
        contactWebsiteView.isAccessibilityElement = true
        contactWebsiteView.accessibilityTraits = .button
        contactWebsiteView.isUserInteractionEnabled = false
        contactWebsiteView.accessibilityValue = "accessibility.dimmed".localized
        contactWebsiteImageView.tintColor = UIColor.systemGray
        contactWebsiteLabel.textColor = UIColor.systemGray
        
        if let contactIssuerImageView = self.contactIssuerImageView,
           let contactIssuerLabel = self.contactIssuerLabel,
           let connectionLabel = self.connectionLabel,
           let contactCallView = self.contactCallView,
           let contactEmailView = self.contactEmailView,
           let contactWebsiteView = self.contactWebsiteView {
            self.accessibilityElements = [contactIssuerImageView, contactIssuerLabel, connectionLabel, contactCallView, contactEmailView, contactWebsiteView]
        }
        
        if contact.contactInfoType == .pobox {
            updateForPOBox(with: contact)
        } else {
            updateForConnection(with: contact)
        }
    }
    
    @objc func onContactCall(_ sender: UITapGestureRecognizer) {
        delegate?.didSelectCall()
    }
    
    @objc func onContactEmail(_ sender: UITapGestureRecognizer) {
        delegate?.didSelectEmail()
    }
    
    @objc func onContactWebsite(_ sender: UITapGestureRecognizer) {
        delegate?.didSelectWebsite()
    }
    
    
    private func updateForPOBox(with contact: Contact) {
        let credentialSubject = contact.profileCredential?.extendedCredentialSubject
        if let consentInfo = credentialSubject?.consentInfo {
            let piiController = consentInfo.piiControllers?.first?.piiController ?? String("-")
            contactIssuerLabel?.text = piiController
        }
        
        if let basicInfo = credentialSubject?.basicInfo {
            let name = basicInfo.controller?.name ?? String("-")
            contactIssuerLabel?.text = name
        }
        
        if let issuerLogoString = contact.profilePackage?.issuerMetadata?.metadata?["logo"] as? String,
           let issuerLogoData = Data(base64Encoded: issuerLogoString, options: .ignoreUnknownCharacters),
           let issuerLogoImage = UIImage(data: issuerLogoData) {
            contactIssuerImageView?.image = issuerLogoImage
        } else {
            //Initials or Image
            let organizationTitle = contact.profileCredential?.extendedCredentialSubject?.consentInfo?.piiControllers?.first?.piiController ?? String()
            
            var initialValue = String()
            let organizationTitleComponents = organizationTitle.components(separatedBy: " ")
            if let first = organizationTitleComponents.first {
                initialValue = String(first.prefix(1))
            }
            if (organizationTitleComponents.count > 1) {
                let second = organizationTitleComponents[1]
                initialValue = String("\(initialValue)\(String(second.prefix(1)))")
            }
            
            let initialLabel = UILabel()
            initialLabel.frame.size = CGSize(width: 100.0, height: 100.0)
            initialLabel.font = UIFont(name: AppFont.regular, size: 48)
            initialLabel.textColor = .label
            initialLabel.text = initialValue
            initialLabel.textAlignment = .center
            initialLabel.backgroundColor = .tertiarySystemBackground
            
            UIGraphicsBeginImageContext(initialLabel.frame.size)
            initialLabel.layer.render(in: UIGraphicsGetCurrentContext()!)
            contactIssuerImageView?.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        
        piiController = credentialSubject?.consentInfo?.piiControllers?.first
        
        if let phone = contact.profileCredential?.extendedCredentialSubject?.consentInfo?.piiControllers?.first?.phone,
           let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
            contactCallView.isUserInteractionEnabled = true
            contactCallView.accessibilityValue = .none
            contactCallImageView.tintColor = UIColor.systemBlue
            contactCallLabel.textColor = UIColor.systemBlue
        }
        
        if let _ = contact.profileCredential?.extendedCredentialSubject?.consentInfo?.piiControllers?.first?.email, MFMailComposeViewController.canSendMail() {
            contactEmailView.isUserInteractionEnabled = true
            contactEmailView.accessibilityValue = .none
            contactEmailImageView.tintColor = UIColor.systemBlue
            contactEmailLabel.textColor = UIColor.systemBlue
        }
        
        if let piiControllerUrlString = contact.profileCredential?.extendedCredentialSubject?.consentInfo?.piiControllers?.first?.piiControllerUrl,
           let _ = URL(string: piiControllerUrlString) {
            contactWebsiteView.isUserInteractionEnabled = true
            contactWebsiteView.accessibilityValue = .none
            contactWebsiteImageView.tintColor = UIColor.systemBlue
            contactWebsiteLabel.textColor = UIColor.systemBlue
        }
    }
    
    private func updateForConnection(with contact: Contact) {
        let credentialSubject = contact.profileCredential?.extendedCredentialSubject
        if let contact = credentialSubject?.rawDictionary?["name"] as? String {
            contactIssuerLabel?.text = contact
        }
        
        if let issuerLogoString = contact.profilePackage?.issuerMetadata?.metadata?["logo"] as? String,
           let issuerLogoData = Data(base64Encoded: issuerLogoString, options: .ignoreUnknownCharacters),
           let issuerLogoImage = UIImage(data: issuerLogoData) {
            contactIssuerImageView?.image = issuerLogoImage
        } else {
            //Initials or Image
            let organizationTitle = contact.profileCredential?.extendedCredentialSubject?.rawDictionary?["name"] as? String ?? String()
            
            var initialValue = String()
            let organizationTitleComponents = organizationTitle.components(separatedBy: " ")
            if let first = organizationTitleComponents.first {
                initialValue = String(first.prefix(1))
            }
            if (organizationTitleComponents.count > 1) {
                let second = organizationTitleComponents[1]
                initialValue = String("\(initialValue)\(String(second.prefix(1)))")
            }
            
            let initialLabel = UILabel()
            initialLabel.frame.size = CGSize(width: 100.0, height: 100.0)
            initialLabel.font = UIFont(name: AppFont.regular, size: 48)
            initialLabel.textColor = .label
            initialLabel.text = initialValue
            initialLabel.textAlignment = .center
            initialLabel.backgroundColor = .tertiarySystemBackground
            
            UIGraphicsBeginImageContext(initialLabel.frame.size)
            initialLabel.layer.render(in: UIGraphicsGetCurrentContext()!)
            contactIssuerImageView?.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        
        if let phone = contact.profileCredential?.extendedCredentialSubject?.rawDictionary?["phone"] as? String,
           let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
            contactCallView.isUserInteractionEnabled = true
            contactCallView.accessibilityValue = .none
            contactCallImageView.tintColor = UIColor.systemBlue
            contactCallLabel.textColor = UIColor.systemBlue
        }
        
        if let email = contact.profileCredential?.extendedCredentialSubject?.rawDictionary?["contact"] as? String, isValidEmail(email),
           MFMailComposeViewController.canSendMail() {
            contactEmailView.isUserInteractionEnabled = true
            contactEmailView.accessibilityValue = .none
            contactEmailImageView.tintColor = UIColor.systemBlue
            contactEmailLabel.textColor = UIColor.systemBlue
        }
        
        if let piiControllerUrlString = contact.profileCredential?.extendedCredentialSubject?.rawDictionary?["website"] as? String,
           let _ = URL(string: piiControllerUrlString) {
            contactWebsiteView.isUserInteractionEnabled = true
            contactWebsiteView.accessibilityValue = .none
            contactWebsiteImageView.tintColor = UIColor.systemBlue
            contactWebsiteLabel.textColor = UIColor.systemBlue
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
