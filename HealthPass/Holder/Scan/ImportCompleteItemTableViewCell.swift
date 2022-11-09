//
//  ImportCompleteItemTableViewCell.swift
//  Holder
//
//  Created by Gautham Velappan on 11/29/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class ImportCompleteItemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var credentialSchemaNameLabel: UILabel?
    @IBOutlet weak var credentialIssuerLabel: UILabel?
    
    @IBOutlet weak var credentialInfo1Label: UILabel?
    @IBOutlet weak var credentialInfo2Label: UILabel?
    @IBOutlet weak var credentialDisplayView: UIView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        credentialSchemaNameLabel?.font = AppFont.headlineScaled
        credentialIssuerLabel?.font = AppFont.subheadlineScaled
        
        credentialInfo1Label?.font = AppFont.footnoteScaled
        credentialInfo2Label?.font = AppFont.footnoteScaled
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

extension ImportCompleteItemTableViewCell {
    
    private func defaultCell() {
        credentialSchemaNameLabel?.text = String("Unknown Schema")
        credentialIssuerLabel?.text = String("Unknown Issuer")
        
        credentialInfo1Label?.text = nil
        credentialInfo2Label?.text = nil
        
        selectionStyle = .none
        isUserInteractionEnabled = false
    }
    
    private func getInfo1Value(for package: Package) -> String? {
        guard let verifiableObject = package.verifiableObject else {
            return nil
        }
        
        if package.type == .SHC {
            guard let jws = verifiableObject.jws,
                  let credentialSubject = jws.payload?.vc?.credentialSubject else {
                      return nil
                  }
            
            guard let fhirBundle = credentialSubject["fhirBundle"] as? [String : Any],
                  let entry = fhirBundle["entry"] as? [[String : Any]],
                  let resources = entry.first?["resource"] as? [String : Any],
                  let name = resources["name"] as? [[String : Any]] else {
                      return nil
                  }
            
            var info1Value = String()
            if let given = name.first?["given"] as? String {
                info1Value = given
            } else if let givenArrayValue = name.first?["given"] as? [Any] {
                let stringArrayValue = givenArrayValue.compactMap{ String(describing: $0) }
                info1Value = stringArrayValue.joined(separator: " ")
            }
            
            if let family = name.first?["family"] as? String {
                info1Value = String("\(info1Value) \(family)")
            }
            
            return info1Value
        }
        
        return nil
    }
    
    private func getInfo2Value(for package: Package) -> String? {
        guard let verifiableObject = package.verifiableObject else {
            return nil
        }
        
        if package.type == .SHC {
            guard let jws = verifiableObject.jws,
                  let credentialSubject = jws.payload?.vc?.credentialSubject else {
                      return nil
                  }
            
            guard let fhirBundle = credentialSubject["fhirBundle"] as? [String : Any],
                  let entry = fhirBundle["entry"] as? [[String : Any]],
                  let resources = entry.first?["resource"] as? [String : Any] else {
                      return nil
                  }
            
            if let birthDateString = resources["birthDate"] as? String {
                let birthDate = Date.dateFromString(dateString: birthDateString)
                return Date.stringForDate(date: birthDate, dateFormatPattern: .fullDate)
            }
            
            return nil
        }
        
        return nil
    }
    
    func populateCell(with package: Package) {
        defaultCell()
        
        var schemaName: String?
        var issuerName: String?
        var primaryColor = UIColor.black
        
        if package.type == .VC || package.type == .IDHP || package.type == .GHP {
            schemaName = package.schema?.name
            issuerName = package.issuerMetadata?.name
            primaryColor = package.credential?.extendedCredentialSubject?.getColor() ?? UIColor.black
        } else if package.type == .SHC {
            schemaName = package.SHCSchemaName
            
            package.SHCIssuerName.done { value in
                issuerName = value
            }.catch { _ in }
            
            primaryColor = package.SHCColor
        } else if package.type == .DCC {
            schemaName = package.DCCSchemaName
            issuerName = package.DCCIssuerName
            primaryColor = package.DCCColor
        }
        
        credentialSchemaNameLabel?.text = schemaName
        credentialIssuerLabel?.text = issuerName
        
        credentialInfo1Label?.text = getInfo1Value(for: package)
        credentialInfo2Label?.text = getInfo2Value(for: package)
        
        credentialDisplayView?.backgroundColor = primaryColor
    }
    
}
