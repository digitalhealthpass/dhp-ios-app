//
//  TestCredentialCell.swift
//  Verifier
//
//  Created by John Martino on 2021-09-10.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit
import VerifiableCredential
import QRCoder

class TestCredentialCell: UITableViewCell {
    @IBOutlet weak var qrImage: UIImageView!
    
    @IBOutlet weak var imageName: UILabel!
    @IBOutlet weak var specLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!

    @IBOutlet weak var statusImage: UIImageView!
    
    var testCredentialItem: TestCredentialItem?
    
    func populate(testCredentialItem: TestCredentialItem) {
        self.testCredentialItem = testCredentialItem
        
        qrImage.image = testCredentialItem.image
        
        imageName.text = testCredentialItem.imageName
        specLabel.text = testCredentialItem.verifiableObject.type.displayValue

        statusLabel.text = testCredentialItem.status.displayValue
        statusLabel.textColor = testCredentialItem.status.tint
        
        errorLabel.text = testCredentialItem.errorMessage

        statusImage.image = UIImage(systemName: testCredentialItem.status.seal)
        statusImage.tintColor = testCredentialItem.status.tint
    }
}
