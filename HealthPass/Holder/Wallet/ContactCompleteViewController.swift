//
//  ContactCompleteViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import Alamofire
import OSLog

extension OSLog {
    static let contactComplete = OSLog(subsystem: subsystem, category: "contactComplete")
}

class ContactCompleteViewController: UIViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        cancelBarButtonItem.isEnabled = false
        addBarButtonItem.isEnabled = false
        
        defaultView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cancelBarButtonItem.isEnabled = false
        addBarButtonItem.isEnabled = false
        
        defaultView()
        constructContact()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationController = segue.destination as? CustomNavigationController else {
            return
        }
        
        if let contactDetailsTableViewController = navigationController.viewControllers.first as? ContactDetailsTableViewController,
           let contact = sender as? Contact {
            contactDetailsTableViewController.contact = contact
        }
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet var addBarButtonItem: UIBarButtonItem!
    
    @IBOutlet var placeholderView: UIView!
    @IBOutlet var contactCardView: GradientView!
    
    @IBOutlet weak var contactIssuerImageView: UIImageView?
    
    @IBOutlet weak var contactPersonLabel: UILabel!
    @IBOutlet weak var contactCompanyLabel: UILabel!
    
    // MARK: - IBAction
    
    @IBAction func onCancel(_ sender: Any) {
        generateImpactFeedback()
        
        showConfirmation(title: "wallet.discard.title".localized, message: "wallet.discard.message".localized,
                         actions: [("wallet.discard.yes".localized, IBMAlertActionStyle.destructive), ("wallet.discard.no".localized, IBMAlertActionStyle.cancel)], completion: { index in
            if index == 0 {
                self.offBoardContact()
            }
        })
        
    }
    
    @IBAction func onAddToWallet(_ sender: Any) {
        guard let contact = contact else {
            self.offBoardContact() //Discard contact if nil
            return
        }
        
        generateImpactFeedback()
        
        cancelBarButtonItem.isEnabled = false
        addBarButtonItem.isEnabled = false
        
        contactCardView?.isHidden = true
        placeholderView?.isHidden = false
        UIAccessibility.post(notification: .screenChanged, argument: placeholderView)
        
        DataStore.shared.saveContact(contact) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.showConfirmationAlert()
                self.generateNotificationFeedback(.success)
                
                DataStore.shared.loadUserData()
                
                self.contactCardView?.isHidden = false
                self.placeholderView?.isHidden = true
            }
        }
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var contactTuple: (Credential, Credential)? {
        didSet {
            didFailCompletion = false
            
            profileCredential = contactTuple?.0
            idCredential = contactTuple?.1
            
            constructContact()
        }
    }
    
    var contact: Contact? {
        didSet {
            updateView()
        }
    }
    
    var uploadFlow: Bool = false
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private var profileCredential: Credential? {
        didSet {
            fetchProfileSchema()
            fetchProfileIssuerMetadata()
        }
    }
    private var profileSchema: Schema?
    private var profileIssuerMetadata: IssuerMetadata?
    
    private var idCredential: Credential? {
        didSet {
            fetchIdSchema()
            fetchIdIssuerMetadata()
        }
    }
    private var idSchema: Schema?
    private var idIssuerMetadata: IssuerMetadata?
    
    private var didFailCompletion: Bool = false
    
    private var didFinishProfileSchemaRequest: Bool = false
    private var profileSchemaRequest: DataRequest?
    
    private var didFinishProfileMetadataRequest: Bool = false
    private var profileIssuerMetaDataRequest: DataRequest?
    
    private var didFinishIdSchemaRequest: Bool = false
    private var idSchemaRequest: DataRequest?
    
    private var didFinishIdMetadataRequest: Bool = false
    private var idIssuerMetaDataRequest: DataRequest?
    
    private let unwindToWalletSegue = "unwindToWallet"
    private let toast = Toast()
    
    // MARK: Private Methods
    
    private func constructContact() {
        guard didFinishProfileSchemaRequest, didFinishProfileMetadataRequest,
              didFinishIdSchemaRequest, didFinishIdMetadataRequest else { return }
        
        var contactDictionary = [String: Any]()
        
        let profilePackage = constructProfilePackage()
        let idPackage = constructIdPackage()
        
        contactDictionary["profilePackage"] = profilePackage?.rawDictionary
        contactDictionary["idPackage"] = idPackage?.rawDictionary
        
        contact = Contact(value: contactDictionary)
    }
    
    private func defaultView() {
        contactIssuerImageView?.image = nil
        contactPersonLabel?.text = String("-")
        contactCompanyLabel?.text = String("-")
        
        contactCardView?.isHidden = true
        placeholderView?.isHidden = false
        
        contactCardView?.primaryColor = .clear
        
        cancelBarButtonItem?.isEnabled = true
        addBarButtonItem?.isEnabled = true
    }
    
    private func updateView() {
        defaultView()
        
        contactCardView?.isHidden = false
        placeholderView?.isHidden = true
        
        let profileCredentialSubject = contact?.profileCredential?.extendedCredentialSubject
        if contact?.contactInfoType == .pobox {
            let piiController = profileCredentialSubject?.consentInfo?.piiControllers?.first
            
            if let contact = piiController?.contact {
                contactPersonLabel?.text = contact
            }
            if let piiController = piiController?.piiController {
                contactCompanyLabel?.text = piiController
            }
        } else {
            if let contact = profileCredentialSubject?.rawDictionary?["contact"] as? String {
                contactPersonLabel?.text = contact
            }
            if let name = profileCredentialSubject?.rawDictionary?["name"] as? String {
                contactCompanyLabel?.text = name
            }
        }
        
        if let issuerLogoString = contact?.profilePackage?.issuerMetadata?.metadata?["logo"] as? String,
           let issuerLogoData = Data(base64Encoded: issuerLogoString, options: .ignoreUnknownCharacters),
           let issuerLogoImage = UIImage(data: issuerLogoData) {
            contactIssuerImageView?.image = issuerLogoImage
        }
    }
    
}

extension ContactCompleteViewController {
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods - Profile
    
    private func constructProfilePackage() -> Package? {
        var packageDictionary = [String: Any]()
        
        packageDictionary["credential"] = profileCredential?.rawString
        packageDictionary["schema"] = profileSchema?.rawString
        packageDictionary["issuerMetadata"] = profileIssuerMetadata?.rawString
        
        return Package(value: packageDictionary)
    }
    
    private func fetchProfileSchema() {
        guard let schemaId = profileCredential?.credentialSchema?.id else {
            self.handleVerificationError()
            return
        }
        
        enableView(false)
        
        //Check Cache
        if let schema = DataStore.shared.getSchema(for: schemaId) {
            self.profileSchema = schema
            self.enableView()
            self.didFinishProfileSchemaRequest = true
            self.constructContact()
            return
        }
        
        profileSchemaRequest = SchemaService().getSchema(schemaId: schemaId) { result in
            switch result {
            case let .success(data):
                guard let payload = data["payload"] as? [String : Any], !(payload.isEmpty) else {
                    self.handleVerificationError()
                    return
                }
                
                let schema = Schema(value: payload)
                DataStore.shared.addNewSchema(schema: schema)
                self.profileSchema = schema
                
            case let .failure(error):
                self.handleVerificationError(error)
            }
            
            self.enableView()
            self.didFinishProfileSchemaRequest = true
            self.constructContact()
        }
    }
    
    private func fetchProfileIssuerMetadata() {
        guard let issuerId = profileCredential?.issuer else {
            return
        }
        
        enableView(false)
        
        //Check Cache
        if let issuerMetadata = DataStore.shared.getIssuerMetadata(for: issuerId) {
            profileIssuerMetadata = issuerMetadata
            enableView()
            didFinishProfileMetadataRequest = true
            constructContact()
            return
        }
        
        profileIssuerMetaDataRequest = IssuerService().getIssuerMetadata(issuerId: issuerId) { result in
            switch result {
            case let .success(data):
                guard let payload = data["payload"] as? [String : Any], !(payload.isEmpty) else {
                    return
                }
                
                let issuerMetadata = IssuerMetadata(value: payload)
                DataStore.shared.addNewIssuerMetadata(issuerMetadata: issuerMetadata)
                self.profileIssuerMetadata = issuerMetadata
                
            case .failure:
                break
            }
            
            self.enableView()
            self.didFinishProfileMetadataRequest = true
            self.constructContact()
        }
    }
    
    private func offBoardContact() {
        //Dismiss the view regardless of the response or action
        guard let orgId = contact?.getOrganizationId(), let contactId = contact?.idPackage?.credential?.extendedCredentialSubject?.id  else {
            self.contact = nil
            self.performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
            return
        }
        
        cancelBarButtonItem.isEnabled = false
        addBarButtonItem.isEnabled = false
        
        contactCardView?.isHidden = true
        placeholderView?.isHidden = false
        
        DataSubmissionService().offBoardContact(for: orgId, contactId: contactId) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.generateNotificationFeedback(.error)
                
                self.contactCardView?.isHidden = false
                self.placeholderView?.isHidden = true
                
                self.contact = nil
                self.performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
            }
        }
    }
}

extension ContactCompleteViewController {
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods - Id
    
    private func constructIdPackage() -> Package? {
        var packageDictionary = [String: Any]()
        
        packageDictionary["credential"] = idCredential?.rawString
        packageDictionary["schema"] = idSchema?.rawString
        packageDictionary["issuerMetadata"] = idIssuerMetadata?.rawString
        
        return Package(value: packageDictionary)
    }
    
    private func fetchIdSchema() {
        guard let schemaId = idCredential?.credentialSchema?.id else {
            self.handleVerificationError()
            return
        }
        
        enableView(false)
        
        //Check Cache
        if let schema = DataStore.shared.getSchema(for: schemaId) {
            self.idSchema = schema
            self.enableView()
            self.didFinishIdSchemaRequest = true
            self.constructContact()
            return
        }
        
        idSchemaRequest = SchemaService().getSchema(schemaId: schemaId) { result in
            switch result {
            case let .success(data):
                guard let payload = data["payload"] as? [String : Any], !(payload.isEmpty) else {
                    self.handleVerificationError()
                    return
                }
                
                let schema = Schema(value: payload)
                DataStore.shared.addNewSchema(schema: schema)
                self.idSchema = schema
                
            case let .failure(error):
                self.handleVerificationError(error)
            }
            
            self.enableView()
            self.didFinishIdSchemaRequest = true
            self.constructContact()
        }
    }
    
    private func fetchIdIssuerMetadata() {
        guard let issuerId = idCredential?.issuer else {
            return
        }
        
        enableView(false)
        
        //Check Cache
        if let issuerMetadata = DataStore.shared.getIssuerMetadata(for: issuerId) {
            idIssuerMetadata = issuerMetadata
            enableView()
            didFinishIdMetadataRequest = true
            constructContact()
            return
        }
        
        idIssuerMetaDataRequest = IssuerService().getIssuerMetadata(issuerId: issuerId) { result in
            switch result {
            case let .success(data):
                guard let payload = data["payload"] as? [String : Any], !(payload.isEmpty) else {
                    return
                }
                
                let issuerMetadata = IssuerMetadata(value: payload)
                DataStore.shared.addNewIssuerMetadata(issuerMetadata: issuerMetadata)
                self.idIssuerMetadata = issuerMetadata
                
            case .failure:
                break
            }
            
            self.enableView()
            self.didFinishIdMetadataRequest = true
            self.constructContact()
        }
    }
    
}

extension ContactCompleteViewController {
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods - Toast and Alerts
    
    private func handleVerificationError(_ error: Error? = nil) {
        guard !didFailCompletion else { return }
        
        didFailCompletion = true
        profileSchemaRequest?.cancel()
        profileIssuerMetaDataRequest?.cancel()
        idSchemaRequest?.cancel()
        idIssuerMetaDataRequest?.cancel()
        
        enableView(false)
        contactCardView?.isHidden = true
        
        let errorTitle = "wallet.verification.title".localized
        var errorMessage = "wallet.verification.message".localized
        
        if let err = error as NSError? {
            let domain = err.domain.isEmpty ? "Domain=Unknown" : "Domain=\(err.domain)"
            let code = "Code=\(err.code)"
            
            errorMessage = errorMessage + String("\n\n(\(domain) | \(code))")
        }
        
        generateNotificationFeedback(.error)
        showConfirmation(title: errorTitle, message: errorMessage,
                         actions: [("Cancel", IBMAlertActionStyle.cancel), ("wallet.verification.retry".localized, IBMAlertActionStyle.default)]) { index in
            self.generateSelectionFeedback()
            if index == 0 {
                self.showConfirmation(title: "wallet.verification.discard.title".localized,
                                      message: "wallet.verification.discard.message".localized,
                                      actions: [("wallet.discard.yes".localized, IBMAlertActionStyle.destructive), ("wallet.discard.no".localized, IBMAlertActionStyle.cancel)]) { index in
                    if index == 0 {
                        self.offBoardContact()
                    }
                }
            } else {
                //Restart the validation
                self.didFinishProfileSchemaRequest = false
                self.didFinishProfileMetadataRequest = false
                self.fetchProfileSchema()
                self.fetchProfileIssuerMetadata()
                
                self.didFinishIdSchemaRequest = false
                self.didFinishIdMetadataRequest = false
                self.fetchIdSchema()
                self.fetchIdIssuerMetadata()
            }
        }
        
    }
    
    private func enableView(_ flag: Bool = true) {
        cancelBarButtonItem?.isEnabled = flag
        addBarButtonItem?.isEnabled = flag
        
        //placeholderView?.isHidden = flag
        contactCardView?.isHidden = !flag
        
        updateViewConstraints()
        view.layoutIfNeeded()
    }
    
    private func showConfirmationAlert() {
        guard contact?.contactInfoType == .both || contact?.contactInfoType == .upload else {
            showConfirmationToast()
            return
        }
        
        showConfirmation(title: "contact.alert.upload.title".localized,
                         message: "contact.alert.upload.message".localized,
                         actions: [("contact.alert.upload.action.no".localized, IBMAlertActionStyle.cancel),("contact.alert.upload.action.yes".localized, IBMAlertActionStyle.default)]) { index in
            self.uploadFlow = (index == 1)
            self.performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
        }
    }
    
    private func showConfirmationToast() {
        toast.label.text = "wallet.success".localized
        toast.glyph.image = UIImage(systemName: "wallet.pass")
        
        toast.layer.setValue("0.01", forKeyPath: "transform.scale")
        toast.alpha = 0
        view.addSubview(toast)
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: [.beginFromCurrentState], animations: {
            self.toast.alpha = 1
            self.toast.layer.setValue(1, forKeyPath: "transform.scale")
            UIAccessibility.post(notification: .screenChanged, argument: self.toast.label)
        }) { (completion) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.beginFromCurrentState], animations: {
                    self.toast.alpha = 0
                    self.toast.layer.setValue(0.8, forKeyPath: "transform.scale")
                }) { (completion) in
                    self.performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
                }
            }
        }
    }
}
