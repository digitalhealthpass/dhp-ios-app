//
//  ContactReachTableViewCell.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class ContactReachTableViewCell: UITableViewCell {

    @IBOutlet weak var phoneTextView: UITextView!
    @IBOutlet weak var emailTextView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        separatorInset = UIEdgeInsets.init(top: 0, left: UIScreen.main.bounds.width, bottom: 0, right: 0)
    }
    
    func populateCell(with contact: Contact) {
        phoneTextView.text = String("-")
        emailTextView.text = String("-")
        
        let piiController = contact.profileCredential?.extendedCredentialSubject?.consentInfo?.piiControllers?.first
        
        if let contact = piiController?.phone {
            phoneTextView.text = contact
        }
        if let piiController = piiController?.email {
            emailTextView.text = piiController
        }
    }

}
