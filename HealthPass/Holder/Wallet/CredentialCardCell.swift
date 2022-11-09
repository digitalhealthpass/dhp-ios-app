//
//  CrdentialCardCell.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class CredentialCardTableViewCell: UITableViewCell {
    
    @IBOutlet weak var issuerName: UILabel!
    @IBOutlet weak var credentialType: UILabel!
    @IBOutlet weak var credentialTypeIcon: UIImageView!
    @IBOutlet weak var expirationDate: UILabel!
    @IBOutlet weak var generateQrBtn: UIButton!
    @IBOutlet weak var expiresLabel: UILabel!
    @IBOutlet weak var viewDetailsBtn: UIButton!
        
    weak var delegate : WalletTableViewControllerDelegate?
    
    // MARK: Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        
        viewDetailsBtn.addTarget(self, action: #selector(onViewDetailsButton(_:)), for: .touchUpInside)
        generateQrBtn.addTarget(self, action: #selector(onQRCodeButton(_:)), for: .touchUpInside)
        
        separatorInset = UIEdgeInsets.init(top: 0, left: UIScreen.main.bounds.width, bottom: 0, right: 0)
        
        generateQrBtn.layer.borderColor = UIColor.link.cgColor
        generateQrBtn.layer.borderWidth = 2
        generateQrBtn.layer.cornerRadius = 5
        generateQrBtn.layer.maskedCorners = [.layerMinXMaxYCorner]
        
        viewDetailsBtn.layer.borderColor = UIColor.link.cgColor
        viewDetailsBtn.layer.borderWidth = 2
        viewDetailsBtn.layer.cornerRadius = 5
        viewDetailsBtn.layer.maskedCorners = [.layerMaxXMaxYCorner]
    }
    
    func populateCell(with package: Package) {
        self.package = package
        
        let type = package.schema?.name
        credentialType.text = type?.capitalized

        let issuer = package.schema?.authorName
        issuerName.text = issuer?.capitalized
        
        if let expireDateString = package.credential?.credentialSubject?.expiryDate {
            let expiryDate = Date.dateFromString(dateString: expireDateString)
            expirationDate?.text = Date.stringForDate(date: expiryDate, dateFormatPattern: .defaultDate)
        } else {
            expirationDate?.text = String("-")
        }
     
    }
    
    @IBAction func onViewDetailsButton(_ sender: Any) {
        delegate?.viewDetailsSelected(for: package)
    }
    
    @IBAction func onQRCodeButton(_ sender: Any) {
        delegate?.generateQRCodesSelected(for: package)
    }

    // ======================================================================
    // === Private API ======================================================
    // ======================================================================
    
    // MARK: Private Properties

    private var package: Package!

}
