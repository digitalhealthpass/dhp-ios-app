//
//  CredentialResultCardTableViewCell.swift
//  Verifier
//
//  Created by Gautham Velappan on 2/24/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import VerifiableCredential

class CredentialResultCardTableViewCell: UITableViewCell {

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    // MARK: - IBOutlet
    
    @IBOutlet weak var credentialContainerView: GradientView!
    
    @IBOutlet weak var credentialIssuerImageView: UIImageView!
    
    @IBOutlet weak var credentialTypeLabel: UILabel!
    @IBOutlet weak var credentialIssuerNameLabel: UILabel!
    @IBOutlet weak var credentialSchemaNameLabel: UILabel!
    
    @IBOutlet weak var issuanceDateLabel: UILabel!
    @IBOutlet weak var expirationDateLabel: UILabel!

    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Methods
    
    func populateCell(_ credential: Credential?, schema: Schema?, issuerMetadata: IssuerMetadata?, issuer: Issuer?) {
        
        let credentialExpired = credential?.isExpired ?? false

        //Defaults
        credentialIssuerImageView?.image = nil
        credentialIssuerImageView?.backgroundColor = .clear
        
        credentialTypeLabel?.text = nil
        credentialIssuerNameLabel?.text = nil
        credentialSchemaNameLabel?.text = nil
        
        issuanceDateLabel?.text = nil
        expirationDateLabel?.text = nil
        
        credentialTypeLabel.text = credential?.credentialSubjectType
        
        let schemaName = schema?.name
        credentialSchemaNameLabel?.text = schemaName
        
        let issuer = issuer?.name ?? (issuerMetadata?.metadata?["name"] as? String)
        credentialIssuerNameLabel.text = issuer
        
        if let issuerLogoString = issuerMetadata?.metadata?["logo"] as? String,
           let issuerLogoData = Data(base64Encoded: issuerLogoString, options: .ignoreUnknownCharacters),
           let issuerLogoImage = UIImage(data: issuerLogoData) {
            credentialIssuerImageView?.image = issuerLogoImage
        }
        
        if let expireDateString = credential?.expirationDate {
            let expString = credentialExpired ? "result.expiredDate".localized : "result.expiresDate".localized
            let expiryDate = Date.dateFromString(dateString: expireDateString)
            expirationDateLabel?.text = String(format: "%@ %@", expString, Date.stringForDate(date: expiryDate, dateFormatPattern: .defaultDate))
        }
        
        if let issuanceDateString = credential?.issuanceDate {
            let issuanceDate = Date.dateFromString(dateString: issuanceDateString)
            issuanceDateLabel?.text = String(format: "result.issuedFormat".localized, Date.stringForDate(date: issuanceDate, dateFormatPattern: .defaultDate))
        }
    }
}
