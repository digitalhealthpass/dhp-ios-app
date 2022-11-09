//
//  CredentialBasicTableViewCell.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class CredentialBasicTableViewCell: UITableViewCell {
    
    @IBOutlet weak var credentialContainerView: UIView?

    @IBOutlet weak var qrCodeImageView: UIImageView?
    @IBOutlet weak var cardExpiredLabel: UILabel?
    
    weak var delegate : CredentialDetailsTableViewControllerDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let generateQRCodeAction = UITapGestureRecognizer(target: self, action: #selector(self.onGenerateQRCode(_:)))
        qrCodeImageView?.addGestureRecognizer(generateQRCodeAction)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func populateCell(with package: Package) {
        if package.type == .VC || package.type == .IDHP || package.type == .GHP {
            credentialContainerView?.backgroundColor = package.credential?.extendedCredentialSubject?.getColor() ?? UIColor.black
        } else if package.type == .SHC  {
            credentialContainerView?.backgroundColor = package.SHCColor
        } else if package.type == .DCC  {
            credentialContainerView?.backgroundColor = package.DCCColor
        }

        let credentialExpired = package.isExpired
        cardExpiredLabel?.isHidden = !credentialExpired
        
        package.fetchQRCodeImage { image, _ in
            self.qrCodeImageView?.image = image
            self.qrCodeImageView?.isUserInteractionEnabled = true
            self.qrCodeImageView?.isAccessibilityElement = true
            let accessibilityText = "accessibility.qrcode".localized
            self.qrCodeImageView?.accessibilityLabel = accessibilityText
        }
    }
    
    @objc func onGenerateQRCode(_ sender: UITapGestureRecognizer) {
        delegate?.generateQRCodesSelected()
    }
    
}
