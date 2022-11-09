//
//  ContactAddressTableViewCell.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class ContactAddressTableViewCell: UITableViewCell {
    
    @IBOutlet weak var addressTextView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        separatorInset = UIEdgeInsets.init(top: 0, left: UIScreen.main.bounds.width, bottom: 0, right: 0)
    }

    func populateCell(with contact: Contact) {
        addressTextView?.text = String("-")
        
        let piiController = contact.profileCredential?.extendedCredentialSubject?.consentInfo?.piiControllers?.first
        
        var address = String()
        if let line = piiController?.address?.line {
            address = String(format: "%@", line)
        }
        
        if let city = piiController?.address?.city {
            address = String(format: "%@\n%@", address, city)
        }
        if let state = piiController?.address?.state {
            address = String(format: "%@, %@", address, state)
        }
        if let postalCode = piiController?.address?.postalCode {
            address = String(format: "%@ %@", address, postalCode)
        }
        if let country = piiController?.address?.country {
            address = String(format: "%@\n%@", address, country)
        }
        
        addressTextView?.text = address
    }
}
