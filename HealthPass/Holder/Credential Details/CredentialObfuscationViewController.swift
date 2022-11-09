//
//  CredentialObfuscationViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

protocol CredentialObfuscationDelegate: AnyObject {
    func shareCredential(_ credential: Credential)
    func displayQRCode(for credential: Credential)
}

class CredentialObfuscationViewController: UIViewController {
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        obfuscationFieldTableView.delegate = self
        obfuscationFieldTableView.dataSource = self
        obfuscationFieldTableView.tableFooterView = UIView()
        
        doneBarButtonItem.title = isDisplayingQRCode ? "Show QR" : "Share"
        
        populateCard()
        setupObfuscationFields()
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var credentialSpecLabel: UILabel!
    @IBOutlet weak var credentialSchemaNameLabel: UILabel!
    @IBOutlet weak var credentialIssuerNameLabel: UILabel!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var dobValueLabel: UILabel?
    @IBOutlet weak var dobLabel: UILabel?
    @IBOutlet weak var expiredLabel: UILabel!
    @IBOutlet weak var credentialIssuerImageView: UIImageView!
    @IBOutlet weak var credentialContainerView: GradientView!
    @IBOutlet weak var obfuscationFieldTableView: UITableView!
    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem!
    
    // MARK: - Properties
    
    var package: Package?
    var isDisplayingQRCode = false
    weak var delegate: CredentialObfuscationDelegate?
    
    // MARK: - Actions
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        guard var credentialDictionary = package?.credential?.rawDictionary else { return }
        
        var obfuscationDictionaries = [[String : Any]]()
        for key in obfuscationFieldKeys {
            guard let value = getObfuscationValue(for: key) else { continue }
            guard let shouldShow = obfuscationFields[key], shouldShow else { continue }
            obfuscationDictionaries.append(value)
        }
        
        credentialDictionary["obfuscation"] = obfuscationDictionaries.count > 0 ? obfuscationDictionaries : nil
        let credential = Credential(value: credentialDictionary)
        dismiss(animated: true) {
            if self.isDisplayingQRCode {
                self.delegate?.displayQRCode(for: credential)
            } else {
                self.delegate?.shareCredential(credential)
            }
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private var obfuscationFields = [String : Bool]()
    private var obfuscationFieldKeys = [String]()
    
    // MARK: - Private Methods
    
    private func getObfuscationValue(for path: String) -> [String : Any]? {
        guard let obfuscationList = package?.credential?.obfuscation else { return nil }
        
        let obfuscation = obfuscationList.filter { $0.path == path }.first
        return obfuscation?.json()
    }
    
    private func populateCard() {
        guard let package = self.package else { return }
        
        let credential = package.credential
        let schema = package.schema
        let issuerMetadata = package.issuerMetadata
        
        let credentialExpired = package.isExpired
        
        expiredLabel?.isHidden = !credentialExpired
        
        let primaryColor = credential?.extendedCredentialSubject?.getColor() ?? UIColor.black
        credentialContainerView.primaryColor = primaryColor
        
        //Defaults
        credentialIssuerImageView?.image = nil
        credentialIssuerImageView?.backgroundColor = .clear
        
        credentialSpecLabel?.text = nil
        credentialIssuerNameLabel?.text = nil
        credentialSchemaNameLabel?.text = nil
        
        fullNameLabel?.text = nil
        dobValueLabel?.text = nil
        
        credentialSpecLabel.text = credential?.extendedCredentialSubject?.type
        
        let schemaName = schema?.name
        credentialSchemaNameLabel?.text = schemaName
        
        let issuer = issuerMetadata?.metadata?["name"] as? String
        credentialIssuerNameLabel.text = issuer
        
        fullNameLabel?.text = package.VCRecipientFullName
        dobValueLabel?.text = package.VCRecipientDOB
        dobLabel?.isHidden = (package.VCRecipientDOB?.isEmpty ?? true)
        
        if let issuerLogoString = issuerMetadata?.metadata?["logo"] as? String,
           let issuerLogoData = Data(base64Encoded: issuerLogoString, options: .ignoreUnknownCharacters),
           let issuerLogoImage = UIImage(data: issuerLogoData) {
            credentialIssuerImageView?.image = issuerLogoImage
        }
    }
    
    private func setupObfuscationFields() {
        guard let fields = package?.credential?.obfuscation else { return }
        for field in fields {
            guard let path = field.path else { continue }
            obfuscationFields[path] = true
            obfuscationFieldKeys.append(path)
        }
    }
}

extension CredentialObfuscationViewController: UITableViewDelegate, UITableViewDataSource {
    // ======================================================================
    // MARK: - UITableView
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        obfuscationFieldKeys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CredentialObfuscationFieldCell.identifier, for: indexPath) as? CredentialObfuscationFieldCell else { return UITableViewCell() }
        
        let key = obfuscationFieldKeys[indexPath.row]
        cell.populate(with: key, isOn: obfuscationFields[key] ?? true)
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section == 0 else { return nil }
        
        return "obfuscation.personalInformation".localized
    }
}

extension CredentialObfuscationViewController: CredentialObfuscationFieldDelegate {
    // MARK: - CredentialObfuscationFieldDelegate
    
    func didChangeValue(for field: String, isOn: Bool) {
        obfuscationFields[field] = isOn
    }
}
