//
//  CredentialDetailsTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import PassKit
import VerificationEngine
import PromiseKit

protocol CredentialDetailsTableViewControllerDelegate: AnyObject {
    func deleteCredentialSelected()
    func generateQRCodesSelected()
}

class CredentialDetailsTableViewController: UITableViewController {
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var shareBarButtonItem: UIBarButtonItem?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        tableView.separatorColor = UIColor(white: 0.85, alpha: 1.0)
        tableView.tableFooterView = UIView()
        
        if let verifiableObject = package?.verifiableObject {
            self.verifyEngine = VerifyEngine(verifiableObject: verifiableObject)
        }
        
        processRecordVerification()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didRefreshKeychain(notification:)),
                                               name: ProfileTableViewController.RefreshKeychainIdentifier,
                                               object: nil)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let credentialQRCodeViewController = segue.destination as? CredentialQRCodeViewController {
            credentialQRCodeViewController.package = package
        } else if let credentialSourceViewController = segue.destination as? CredentialSourceViewController {
            credentialSourceViewController.package = package
        } else if let obfuscationNavigationController = segue.destination as? UINavigationController, let obfuscationFieldsViewController = obfuscationNavigationController.viewControllers.first as? CredentialObfuscationViewController {
            obfuscationFieldsViewController.package = package
            obfuscationFieldsViewController.delegate = self
            obfuscationFieldsViewController.isDisplayingQRCode = isDisplayQRSelected
        } else if let customNavigationController = segue.destination as? CustomNavigationController,
                  let connectionListTableViewController = customNavigationController.viewControllers.first as? ConnectionListTableViewController {
            connectionListTableViewController.package = package
        }
    }
    
    @IBAction func unwindToCredentialDetails(segue: UIStoryboardSegue) {
        prepareForTable()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.tableView.reloadData()
        }
    }
    
    
    @objc
    func didRefreshKeychain(notification: Notification) {
        self.navigationController?.popToRootViewController(animated: true)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
        }
    }
    
    // MARK: - IBAction
    
    @IBAction func onDone(_ sender: Any) {
        performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
    }
    
    @IBAction func onShare(_ sender: UIBarButtonItem) {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "cred.share.title".localized,
                                      message: "cred.share.message".localized,
                                      preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.placeholder = "label.placeholder.fileName".localized
            textField.font = UIFont.textFieldDefaultFont
            textField.text = self.package?.schema?.name
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks Generate.
        alert.addAction(UIAlertAction(title: "alert.shareButtonTitle".localized, style: .default, handler: { _ in
            guard let fileName = alert.textFields?.first?.text, !fileName.isEmpty else {
                self.showConfirmation(title: "cred.share.failed.title".localized,
                                      message: "cred.share.failed.message".localized,
                                      actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
                return
            }
            self.w3cFileName = fileName
            self.obfuscationSettingsAndShare()
        }))
        
        // 3. Grab the value from the text field, and print it when the user clicks Generate.
        alert.addAction(UIAlertAction(title: "button.title.cancel".localized, style: .cancel, handler: nil))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var package: Package? {
        didSet {
            prepareForTable()
        }
    }
    
    var verifyEngine: VerifyEngine!
    
    var hasAssociatedConnections: Bool {
        return !(package?.associatedContacts?.isEmpty ?? true)
    }
    
    var hasCredentialInfo: Bool {
        return !credentialInfo.isEmpty
    }
 
    var numberOfSections = 0
    
    var credentialInfo: [CredentialInfoTableViewCellModel] {
        var credentialInfo: [CredentialInfoTableViewCellModel] = []
        
        if let issuanceDateValue = package?.issuanceDateValue {
            credentialInfo.append(CredentialInfoTableViewCellModel(title: "cred.issuedDate".localized, value: Date.stringForDate(date: issuanceDateValue, dateFormatPattern: .fullDateTime)))
        }
        
        if let expirationDateValue = package?.expirationDateValue {
            let title = (package?.isExpired ?? false)
            ? "cred.expiredDate".localized
            : "cred.expiresDate".localized
            
            let value = Date.stringForDate(date: expirationDateValue, dateFormatPattern: .fullDateTime)
            
            credentialInfo.append(CredentialInfoTableViewCellModel(title: title, value: value))
        }
        
        return credentialInfo
    }
 
    var recordVerification: [CredentialInfoTableViewCellModel] = []
    
    var displayFieldsDictionary = [Int: [DisplayField]]() {
        didSet {
            numberOfSections = 6
            
            if hasAssociatedConnections {
                numberOfSections = numberOfSections + 1
            }
            
            if hasCredentialInfo {
                numberOfSections = numberOfSections + 1
            }
            
            numberOfSections = numberOfSections + displayFieldsDictionary.keys.count
            tableView.reloadData()
        }
    }
    
    var fieldsDictionary = [String: [Field]]() {
        didSet {
            numberOfSections = 6
            
            if hasAssociatedConnections {
                numberOfSections = numberOfSections + 1
            }
            
            if hasCredentialInfo {
                numberOfSections = numberOfSections + 1
            }
            
            numberOfSections = numberOfSections + fieldsDictionary.keys.count
            tableView.reloadData()
        }
    }
    
    let showCredentialSourceSegue = "showCredentialSource"
    let showConnectionListSegue = "showConnectionList"
    let unwindToWalletSegue = "unwindToWallet"
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private var displayFields: [DisplayField] = [] {
        didSet {
            var displayFieldsDictionary = [Int: [DisplayField]]()
            
            displayFields.forEach { displayField in
                let sectionIndex = displayField.sectionIndex ?? Int.max
                
                var sectionDisplayFields = displayFieldsDictionary[sectionIndex] ?? [DisplayField]()
                sectionDisplayFields.append(displayField)
                
                displayFieldsDictionary[sectionIndex] = sectionDisplayFields
            }
            
            self.displayFieldsDictionary = displayFieldsDictionary
        }
    }
    
    
    private var fields: [Field]?
    
    private let showCredentialQRCodeSegue = "showCredentialQRCode"
    private let showObfuscationFieldsSegue = "obfuscationFieldsSegue"
    
    private var w3cFileName: String?
    private var isDisplayQRSelected = false
    
    // MARK: Private Methods
    
    private func processRecordVerification() {
        recordVerification.append(CredentialInfoTableViewCellModel(title: "Signature", processed: false))
        recordVerification[0].value = "result.Verifying".localized
        
        isValidSignature()
            .done { _ in
                self.recordVerification[0].value = "result.Verified".localized + " - " + "credential.details.signature.valid".localized
                self.recordVerification[0].success = true
            }
            .catch { error in
                self.recordVerification[0].success = false
                if error as NSError == .credentialSignatureUnavailableKey {
                    self.recordVerification[0].value = "result.notVerified".localized + " - " + "credential.details.signature.unknownIssuer".localized
                } else {
                    self.recordVerification[0].value = "result.notVerified".localized + " - " + "credential.details.signature.invalid".localized
                }
            }.finally {
                self.recordVerification[0].processed = true
              
                UIView.performWithoutAnimation {
                    self.tableView.reloadData()
                }
            }
        
        guard package?.type == .IDHP || package?.type == .GHP || package?.type == .VC else {
            return
        }
        
        recordVerification.append(CredentialInfoTableViewCellModel(title: "Status", processed: false))
        recordVerification[1].value = "result.Verifying".localized
        
        isNotRevoked()
            .done { _ in
                self.recordVerification[1].value = "credential.details.status.notRevoked".localized
                self.recordVerification[1].success = true
            }
            .catch { _ in
                self.recordVerification[1].value = "credential.details.status.revoked".localized
                self.recordVerification[1].success = false
            }
            .finally {
                self.recordVerification[1].processed = true
                
                UIView.performWithoutAnimation {
                    self.tableView.reloadData()
                }
            }
    }
    
    private func updateCredentialStatus(with value: String) {
        self.recordVerification[0].value = value
        
    }
    
    private func obfuscationSettingsAndShare() {
        if package?.credential?.obfuscation != nil {
            performSegue(withIdentifier: showObfuscationFieldsSegue, sender: nil)
        } else {
            share(credential: package?.credential)
        }
    }
    
    private func share(credential: Credential?) {
        guard let credential = credential, let fileURL = credential.saveAsW3C(with: w3cFileName) else {
            self.showAlert(title: "cred.share.title".localized, message: "cred.share.fail.message".localized, actions: ["button.title.ok".localized])
            return
        }
        
        let fileURLs = [fileURL]
        let shareSheetController = UIActivityViewController(activityItems: fileURLs, applicationActivities: nil)
        
        if let popoverController = shareSheetController.popoverPresentationController {
            popoverController.barButtonItem = shareBarButtonItem
            
            popoverController.permittedArrowDirections = [.up]
        }
        
        present(shareSheetController, animated: true)
    }
    
    private func prepareForTable() {
        guard let package = package else {
            return
        }
        
        var titleName = String()
        var credentialSubjectDictionary = [String: Any]()
        var schemaDictionary = [String: Any]()
        
        switch package.type {
        case .VC, .IDHP, .GHP:
            if let schema = package.schema?.schema {
                schemaDictionary = schema
            }
            
            if let payload = package.verifiableObject?.payload as? [String: Any],
               let credentialSubject = payload["credentialSubject"] as? [String: Any] {
                credentialSubjectDictionary = credentialSubject
            }
            
            let allUnsortedFields = SchemaParser().getVisibleFields(for: credentialSubjectDictionary, and: schemaDictionary)
            fields = allUnsortedFields.filter { $0.visible ?? true }
            
            fieldsDictionary = [String: [Field]]()
            fields?.forEach { field in
                if let parent = field.parentKey {
                    var fields = fieldsDictionary[parent] ?? [Field]()
                    fields.append(field)
                    fieldsDictionary[parent] = fields
                } else {
                    var fields = fieldsDictionary["details"] ?? [Field]()
                    fields.append(field)
                    fieldsDictionary["details"] = fields
                }
            }
            
            if let schemaName = package.schema?.name {
                titleName = schemaName
            }
            
        case .SHC:
            self.displayFields = prepareDisplayFields() ?? [DisplayField]()
            
            if let schemaName = package.SHCSchemaName {
                titleName = schemaName
            }
            
        case .DCC:
            self.displayFields = prepareDisplayFields() ?? [DisplayField]()
            
            if let schemaName = package.DCCSchemaName {
                titleName = schemaName
            }
            
        default:
            return
        }
        
        title = titleName
    }
    
}

extension CredentialDetailsTableViewController : CredentialDetailsTableViewControllerDelegate {
    
    func deleteCredentialSelected() {
        guard let package = self.package else {
            return
        }
        self.showConfirmation(title: "cred.delete.alertTitle".localized, message: "cred.delete.message".localized,
                              actions: [("cred.delete.title".localized, IBMAlertActionStyle.destructive), ("button.title.cancel".localized, IBMAlertActionStyle.cancel)], completion: { index in
            if index == 0 {
                DataStore.shared.deletePackage(package) { _ in
                    self.generateNotificationFeedback(.error)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        DataStore.shared.loadUserData()
                        self.performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
                    }
                }
            }
        })
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
        
    }
    
    func generateQRCodesSelected() {
        if let obfuscation = package?.credential?.obfuscation, !(obfuscation.isEmpty) {
            isDisplayQRSelected = true
            performSegue(withIdentifier: showObfuscationFieldsSegue, sender: nil)
        } else {
            showQRCode()
        }
    }
    
    private func showQRCode() {
        generateImpactFeedback()
        
        self.performSegue(withIdentifier: showCredentialQRCodeSegue, sender: nil)
        
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }
    }
}

extension CredentialDetailsTableViewController: CredentialObfuscationDelegate {
    
    func shareCredential(_ credential: Credential) {
        share(credential: credential)
    }
    
    func displayQRCode(for credential: Credential) {
        showQRCode()
        isDisplayQRSelected = false
    }
    
}
