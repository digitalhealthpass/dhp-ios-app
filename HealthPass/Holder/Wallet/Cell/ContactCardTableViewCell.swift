//
//  ContactCardTableViewCell.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class ContactCardTableViewCell: UITableViewCell {
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        separatorInset = UIEdgeInsets.init(top: 0, left: UIScreen.main.bounds.width, bottom: 0, right: 0)
    }
    
    // MARK: - IBOutlet
    @IBOutlet weak var contactContainerView: UIView!

    @IBOutlet weak var contactIssuerImageView: UIImageView?
    
    @IBOutlet weak var contactIssuerLabel: UILabel?
    @IBOutlet weak var contactContactLabel: UILabel?
    @IBOutlet weak var stateImageView: UIImageView?
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Methods
    
    func populateCell(with contact: Contact) {
        contactIssuerImageView?.image = nil
        contactIssuerImageView?.isHidden = true
        
        contactContactLabel?.text = String("-")
        contactIssuerLabel?.text = String("-")
        
        let profileCredentialSubject = contact.profileCredential?.extendedCredentialSubject
        if contact.contactInfoType == .pobox {
            let piiController = profileCredentialSubject?.consentInfo?.piiControllers?.first
            
            if let contact = piiController?.contact {
                contactContactLabel?.text = contact
            }
            if let piiController = piiController?.piiController {
                contactIssuerLabel?.text = piiController
            }
        } else {
            if let contact = profileCredentialSubject?.rawDictionary?["contact"] as? String {
                contactContactLabel?.text = contact
            }
            if let name = profileCredentialSubject?.rawDictionary?["name"] as? String {
                contactIssuerLabel?.text = name
            }
        }
        
        if let issuerLogoString = contact.profilePackage?.issuerMetadata?.metadata?["logo"] as? String,
           let issuerLogoData = Data(base64Encoded: issuerLogoString, options: .ignoreUnknownCharacters),
           let issuerLogoImage = UIImage(data: issuerLogoData) {
            contactIssuerImageView?.image = issuerLogoImage
            contactIssuerImageView?.isHidden = false
        }
    }
    
    func resetCell() {
        contactContainerView.layer.borderColor = UIColor.clear.cgColor
        contactContainerView.layer.borderWidth = 0
        
        contactContainerView.transform = CGAffineTransform.identity
    }

    func selectedCell() {
        contactContainerView.layer.borderColor = UIColor.systemBlue.cgColor
        contactContainerView.layer.borderWidth = 4.0
        
        UIView.animate(withDuration: 0.15, animations: {
            self.contactContainerView.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        }) { (finished) in
            UIView.animate(withDuration: 0.15, animations: {
                self.contactContainerView.transform = CGAffineTransform.identity
            })
        }
    }
    
    func didSelected() {
        stateImageView?.image = UIImage(systemName: "checkmark.circle.fill")
    }
    
    func didDeselected() {
        stateImageView?.image = UIImage(systemName: "circle")
    }
}
