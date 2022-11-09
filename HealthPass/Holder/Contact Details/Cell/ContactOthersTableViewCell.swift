//
//  ContactOthersTableViewCell.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class ContactOthersTableViewCell: UITableViewCell {

    @IBOutlet weak var urlTextView: UITextView!

    @IBOutlet weak var jurisdictionLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        separatorInset = UIEdgeInsets.init(top: 0, left: UIScreen.main.bounds.width, bottom: 0, right: 0)
    }
    
    func populateCell(with contact: Contact) {
        urlTextView?.text = String("-")

        versionLabel?.text = String("-")
        jurisdictionLabel?.text = String("-")

        let consentInfo = contact.profileCredential?.extendedCredentialSubject?.consentInfo
        let piiController = consentInfo?.piiControllers?.first
        
        if let url = piiController?.piiControllerUrl {
            urlTextView?.text = url
        }
        
        if let version = consentInfo?.version {
            versionLabel?.text = version
        }
        if let jurisdiction = consentInfo?.jurisdiction {
            jurisdictionLabel?.text = jurisdiction
        }
    }


}
