//
//  CrdentialCardCell.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class CredentialCardTableViewCell: UITableViewCell {
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        expiredLabel?.transform = CGAffineTransform(rotationAngle: 3*(.pi/2))
        
        separatorInset = UIEdgeInsets.init(top: 0, left: UIScreen.main.bounds.width, bottom: 0, right: 0)
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var credentialContainerView: GradientView!
    
    @IBOutlet weak var credentialIssuerImageView: UIImageView!
    
    @IBOutlet weak var credentialIssuerNameLabel: UILabel!
    @IBOutlet weak var credentialSchemaNameLabel: UILabel!
    
    @IBOutlet weak var fullNameLabel: UILabel?
    @IBOutlet weak var dobValueLabel: UILabel?
    @IBOutlet weak var dobLabel: UILabel?
    
    @IBOutlet weak var credentialSpecLabel: UILabel?
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView?
    @IBOutlet weak var expiredLabel: UILabel?
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Methods
    
    func populateCell(with package: Package) {
        self.package = package
        expiredLabel?.isHidden = !package.isExpired
        activityIndicatorView?.isHidden = true
        //Defaults
        credentialIssuerImageView?.image = nil
        credentialIssuerImageView?.backgroundColor = .clear
        
        credentialIssuerNameLabel?.text = nil
        credentialSchemaNameLabel?.text = nil
        fullNameLabel?.text = nil
        dobValueLabel?.text = nil
        credentialSpecLabel?.text = nil
        
        credentialContainerView.primaryColor = UIColor.black
        
        switch package.type {
        case .VC, .IDHP, .GHP:
            setupForVC()
        case .SHC:
            setupForSHC()
        case .DCC:
            setupForDCC()
        default:
            break
        }

        updateTextColor()
    }
    
    func resetCell() {
        credentialContainerView.resetView()
    }
    
    func selectedCell() {
        credentialContainerView.selectedView()
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private var package: Package!
    
    private func setupForVC() {
        credentialSchemaNameLabel?.text = package.schema?.name
        
        let issuer = package.issuerMetadata?.metadata?["name"] as? String
        credentialIssuerNameLabel.text = issuer
        
        fullNameLabel?.text = package.VCRecipientFullName
        dobValueLabel?.text = package.VCRecipientDOB
        dobLabel?.isHidden = (package.VCRecipientDOB?.isEmpty ?? true)
        
        credentialSpecLabel?.text = package.type.displayValue

        if let issuerLogoString = package.issuerMetadata?.metadata?["logo"] as? String,
           let issuerLogoData = Data(base64Encoded: issuerLogoString, options: .ignoreUnknownCharacters),
           let issuerLogoImage = UIImage(data: issuerLogoData) {
            credentialIssuerImageView?.image = issuerLogoImage
        }

        credentialContainerView.primaryColor = package.credential?.extendedCredentialSubject?.getColor() ?? UIColor.black
    }
    
    private func setupForSHC() {
        activityIndicatorView?.isHidden = false
        activityIndicatorView?.startAnimating()
        credentialIssuerNameLabel?.text = "Loading.."
        credentialSchemaNameLabel?.text = package.SHCSchemaName
        
        package.SHCIssuerName.done { value in
            self.credentialIssuerNameLabel?.text = value
            self.activityIndicatorView?.stopAnimating()
            self.activityIndicatorView?.isHidden = true
        }.catch { _ in }
        
        fullNameLabel?.text = package.SHCRecipientFullName
        dobValueLabel?.text = package.SHCRecipientDOB
        dobLabel?.isHidden = (package.SHCRecipientDOB?.isEmpty ?? true)

        credentialSpecLabel?.text = package.type.displayValue
       
        credentialIssuerImageView?.image = nil
       
        credentialContainerView.primaryColor = package.SHCColor
    }
    
    private func setupForDCC() {
        credentialSchemaNameLabel?.text = package.DCCSchemaName
        credentialIssuerNameLabel?.text = package.DCCIssuerName
        
        fullNameLabel?.text = package.DCCRecipientFullName
        dobValueLabel?.text = package.DCCRecipientDOB
        dobLabel?.isHidden = (package.DCCRecipientDOB?.isEmpty ?? true)

        credentialSpecLabel?.text = package.type.displayValue
        
        credentialIssuerImageView?.image = nil
        
        credentialContainerView.primaryColor = package.DCCColor
    }
    
    private func updateTextColor() {
        let isDarkColor = credentialContainerView.primaryColor.isDarkColor
        activityIndicatorView?.tintColor = isDarkColor ? .white : .black
        credentialIssuerNameLabel.textColor = isDarkColor ? .white : .black
        credentialSchemaNameLabel.textColor = isDarkColor ? .white : .black
        credentialSpecLabel?.textColor = isDarkColor ? .white : .black
        fullNameLabel?.textColor = isDarkColor ? .white : .black
        dobLabel?.textColor = isDarkColor ? .white : .black
        dobValueLabel?.textColor = isDarkColor ? .white : .black
    }
    
    private func getValue(at path: String, for json: [String: Any]) -> String? {
        var path = path.replacingOccurrences(of: "[", with: ".", options: .literal, range: nil)
        path = path.replacingOccurrences(of: "]", with: "", options: .literal, range: nil)
        
        let keys = path.components(separatedBy: ".")
        var trimmedValue: Any? = json
        
        var value: String?
        keys.forEach { key in
            
            if let index = Int(key) {
                guard let loopingValue = trimmedValue as? [Any], !(loopingValue.isEmpty), loopingValue.count > index else {
                    return
                }
                
                if keys.last == key {
                    let val = loopingValue[index]
                    if let directValue = val as? String {
                        value = directValue
                    } else if let arrayValue = val as? [Any] {
                        let stringArrayValue = arrayValue.compactMap{ String(describing: $0) }
                        value = stringArrayValue.joined(separator: " ")
                    } else if let dictionaryValue = val as? [String: Any], let data = try? JSONSerialization.data(withJSONObject: dictionaryValue, options: [.sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]) as Data {
                        value = String(data: data, encoding: .utf8)
                    } else {
                        value = String(describing: val)
                    }
                }
                
                trimmedValue = loopingValue[index]
            } else {
                let loopingValue: [String: Any]
                
                if let value = trimmedValue as? [String: Any], !(value.isEmpty) {
                    loopingValue = value
                } else if let value = trimmedValue as? [[String: Any]], !(value.isEmpty) {
                    loopingValue = value[0]
                } else {
                    return
                }
                
                if keys.last == key, let val = loopingValue[key] {
                    if let directValue = val as? String {
                        value = directValue
                    } else if let arrayValue = val as? [Any] {
                        let stringArrayValue = arrayValue.compactMap{ String(describing: $0) }
                        value = stringArrayValue.joined(separator: " ")
                    } else if let dictionaryValue = val as? [String: Any], let data = try? JSONSerialization.data(withJSONObject: dictionaryValue, options: [.sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]) as Data {
                        value = String(data: data, encoding: .utf8)
                    } else {
                        value = String(describing: val)
                    }
                }
                
                trimmedValue = loopingValue[key]
            }
        }
        
        return value
    }
    
}
