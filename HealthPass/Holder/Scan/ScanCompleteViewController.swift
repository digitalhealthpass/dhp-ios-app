//
//  ScanCompleteViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import AVFoundation
import Foundation

class ScanCompleteViewController: UIViewController {
    
    var credentialString: String? {
        didSet {
            if let string = credentialString {
                verifiableObject = VerifiableObject(string: string)
            }
        }
    }
    
    var credentialData: Data? {
        didSet {
            if let data = credentialData {
                verifiableObject = VerifiableObject(data: data)
            }
        }
    }

    @IBOutlet var cancelBarButtonItem: UIBarButtonItem?
    @IBOutlet var addBarButtonItem: UIBarButtonItem?
    
    @IBOutlet var placeholderView: UIView?
    @IBOutlet var credentialView: GradientView?
    @IBOutlet weak var credentialViewCenterConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var credentialIssuerImageView: UIImageView?
    
    @IBOutlet weak var credentialSpecLabel: UILabel?
    @IBOutlet weak var credentialIssuerNameLabel: UILabel?
    @IBOutlet weak var credentialSchemaNameLabel: UILabel?
    @IBOutlet weak var credentialActivityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var fullNameLabel: UILabel?
    @IBOutlet weak var dobLabel: UILabel?
    @IBOutlet weak var dobValueLabel: UILabel?
    
    @IBOutlet weak var replaceCardInfoLabel: UILabel?
    @IBOutlet weak var replaceCardImageView: UIImageView?
    
    @IBOutlet var existingCredentialView: GradientView?
    
    @IBOutlet weak var existingCredentialIssuerImageView: UIImageView?
    
    @IBOutlet weak var existingCredentialSpecLabel: UILabel?
    @IBOutlet weak var existingCredentialIssuerNameLabel: UILabel?
    @IBOutlet weak var existingCredentialSchemaNameLabel: UILabel?
    
    @IBOutlet weak var existingFullNameLabel: UILabel?
    @IBOutlet weak var existingDOBLabel: UILabel?
    @IBOutlet weak var existingDOBValueLabel: UILabel?
    @IBOutlet weak var existingCredentialActivityIndicatorView: UIActivityIndicatorView?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        addBarButtonItem?.title = "scan.add".localized
        
        credentialViewCenterConstraint?.isActive = true
        
        existingCredentialView?.isHidden = true
        replaceCardImageView?.isHidden = true
        replaceCardInfoLabel?.isHidden = true
        
        enableView(false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cancelBarButtonItem?.isEnabled = false
        addBarButtonItem?.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let type = verifiableObject?.type, (type == .IDHP || type == .GHP || type == .VC), let _ = verifiableObject?.credential {
            fetchSchema()
        } else if let type = verifiableObject?.type, (type == .SHC || type == .DCC) {
            checkExisting()
        } else {
            handleUnsupportedCredentials()
        }
        
    }
    
    @IBAction func onCancel(_ sender: Any) {
        self.package = nil
        performSegue(withIdentifier: unwindToWalletSegue, sender: nil)
    }
    
    @IBAction func onAddToWallet(_ sender: Any) {
        addToWallet()
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Properties
    
    internal var package: Package? {
        didSet {
            updateView()
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private let unwindToWalletSegue = "unwindToWallet"
    
    var verifiableObject: VerifiableObject? {
        didSet {
            updatePackage()
        }
    }
    
    private var schema: Schema? {
        didSet {
            fetchIssuerMetadata()
            updatePackage()
        }
    }
    
    private var issuerMetadata: IssuerMetadata? {
        didSet {
            updatePackage()
        }
    }
    
    private var existingPackage: Package? {
        didSet {
            enableView()
            updateView()
        }
    }
    
    // MARK: - Private Methods
    
    private func handleUnsupportedCredentials() {
        enableView(false)
        credentialView?.isHidden = true
        
        let errorTitle = "wallet.unsupported.title".localized
        let errorMessage = "wallet.unsupported.message".localized
        
        generateNotificationFeedback(.error)
        showConfirmation(title: errorTitle, message: errorMessage, actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)]) { _ in
            self.generateSelectionFeedback()
            self.package = nil
            self.performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
        }
    }
    
    private func updatePackage() {
        var packageDictionary = [String: Any]()
        
        packageDictionary["credential"] = verifiableObject?.rawString
        packageDictionary["schema"] = schema?.rawString
        packageDictionary["issuerMetadata"] = issuerMetadata?.rawString
        
        package = Package(value: packageDictionary)
    }
    
    private func updateView() {
        //Defaults
        credentialIssuerImageView?.image = nil
        credentialIssuerImageView?.backgroundColor = .clear
        credentialActivityIndicatorView?.isHidden = true
        credentialIssuerNameLabel?.text = nil
        credentialSchemaNameLabel?.text = nil
        credentialSpecLabel?.text = nil
        fullNameLabel?.text = nil
        dobValueLabel?.text = nil
        
        guard let package = package else {
            return
        }
        
        switch package.type {
        case .VC, .IDHP, .GHP:
            setupVCCredential(with: package)
        case .SHC:
            setupSHCCredential(with: package)
        case .DCC:
            setupDCCCredential(with: package)
        default:
            break
        }

        updateNewTextColor(for: credentialView?.primaryColor ?? UIColor.black)
        
        if existingPackage != nil {
            updateExistingCredential()
        }
    }
    
    private func updateExistingCredential() {
        addBarButtonItem?.title = "scan.replace".localized
        
        credentialViewCenterConstraint?.isActive = false
        
        existingCredentialView?.isHidden = false
        replaceCardImageView?.isHidden = false
        replaceCardInfoLabel?.isHidden = false
        
        //Defaults
        existingCredentialIssuerImageView?.image = nil
        existingCredentialIssuerImageView?.backgroundColor = .clear
        existingCredentialActivityIndicatorView?.isHidden = true
        existingCredentialIssuerNameLabel?.text = nil
        existingCredentialSchemaNameLabel?.text = nil
        existingDOBValueLabel?.text = nil
        existingFullNameLabel?.text = nil
        existingCredentialSpecLabel?.text = nil
        
        guard let package = package else {
            return
        }
        
        switch package.type {
        case .VC, .IDHP, .GHP:
            setupVCExistingCredential(with: package)
        case .SHC:
            setupSHCExistingCredential(with: package)
        case .DCC:
            setupDCCExistingCredential(with: package)
        default:
            break
        }
        
        updateExistingTextColor(for: existingCredentialView?.primaryColor ?? UIColor.black)
    }
    
    private func setupVCExistingCredential(with package: Package) {
        existingCredentialSchemaNameLabel?.text = package.schema?.name
        
        let issuer = package.issuerMetadata?.metadata?["name"] as? String
        existingCredentialIssuerNameLabel?.text = issuer
        
        existingFullNameLabel?.text = package.VCRecipientFullName
        existingDOBValueLabel?.text = package.VCRecipientDOB
        existingDOBLabel?.isHidden = (package.VCRecipientDOB?.isEmpty ?? true)

        existingCredentialSpecLabel?.text = package.type.displayValue

        if let issuerLogoString = package.issuerMetadata?.metadata?["logo"] as? String,
           let issuerLogoData = Data(base64Encoded: issuerLogoString, options: .ignoreUnknownCharacters),
           let issuerLogoImage = UIImage(data: issuerLogoData) {
            existingCredentialIssuerImageView?.image = issuerLogoImage
        }

        existingCredentialView?.primaryColor = package.credential?.extendedCredentialSubject?.getColor() ?? UIColor.black
    }
    
    private func setupSHCExistingCredential(with package: Package) {
        existingCredentialActivityIndicatorView?.isHidden = false
        existingCredentialActivityIndicatorView?.startAnimating()
        existingCredentialIssuerNameLabel?.text = "Loading.."
        existingCredentialSchemaNameLabel?.text = package.SHCSchemaName
        
        package.SHCIssuerName.done { value in
            self.existingCredentialIssuerNameLabel?.text = value
            self.existingCredentialActivityIndicatorView?.isHidden = true
            self.existingCredentialActivityIndicatorView?.stopAnimating()
        }.catch { _ in }
        
        existingFullNameLabel?.text = package.SHCRecipientFullName
        existingDOBValueLabel?.text = package.SHCRecipientDOB
        existingDOBValueLabel?.isHidden = (package.SHCRecipientDOB?.isEmpty ?? true)

        existingCredentialSpecLabel?.text = package.type.displayValue
       
        existingCredentialIssuerImageView?.image = nil
       
        existingCredentialView?.primaryColor = package.SHCColor
    }
    
    private func setupDCCExistingCredential(with package: Package) {
        existingCredentialSchemaNameLabel?.text = package.DCCSchemaName
        existingCredentialIssuerNameLabel?.text = package.DCCIssuerName
        
        existingFullNameLabel?.text = package.DCCRecipientFullName
        existingDOBValueLabel?.text = package.DCCRecipientDOB
        existingDOBValueLabel?.isHidden = (package.DCCRecipientDOB?.isEmpty ?? true)
        
        credentialSpecLabel?.text = package.type.displayValue
       
        existingCredentialIssuerImageView?.image = nil
       
        existingCredentialView?.primaryColor = package.DCCColor
    }
    
    private func setupVCCredential(with package: Package) {
        credentialSchemaNameLabel?.text = package.schema?.name
        
        let issuer = package.issuerMetadata?.metadata?["name"] as? String
        credentialIssuerNameLabel?.text = issuer
        
        fullNameLabel?.text = package.VCRecipientFullName
        dobValueLabel?.text = package.VCRecipientDOB
        dobLabel?.isHidden = (package.VCRecipientDOB?.isEmpty ?? true)

        credentialSpecLabel?.text = package.type.displayValue

        if let issuerLogoString = package.issuerMetadata?.metadata?["logo"] as? String,
           let issuerLogoData = Data(base64Encoded: issuerLogoString, options: .ignoreUnknownCharacters),
           let issuerLogoImage = UIImage(data: issuerLogoData) {
            credentialIssuerImageView?.image = issuerLogoImage
        }

        credentialView?.primaryColor = package.credential?.extendedCredentialSubject?.getColor() ?? UIColor.black
    }
    
    private func setupSHCCredential(with package: Package) {
        credentialActivityIndicatorView?.isHidden = false
        credentialActivityIndicatorView?.startAnimating()
        credentialIssuerNameLabel?.text = "Loading.."
        credentialSchemaNameLabel?.text = package.SHCSchemaName
        
        package.SHCIssuerName.done { value in
            self.credentialIssuerNameLabel?.text = value
            self.credentialActivityIndicatorView?.isHidden = true
            self.credentialActivityIndicatorView?.stopAnimating()
        }.catch { _ in }
        
        fullNameLabel?.text = package.SHCRecipientFullName
        dobValueLabel?.text = package.SHCRecipientDOB
        dobLabel?.isHidden = (package.SHCRecipientDOB?.isEmpty ?? true)

        credentialSpecLabel?.text = package.type.displayValue
       
        credentialIssuerImageView?.image = nil
       
        existingCredentialView?.primaryColor = package.SHCColor

        credentialView?.primaryColor = package.SHCColor
    }
    
    private func setupDCCCredential(with package: Package) {
        credentialSchemaNameLabel?.text = package.DCCSchemaName
        credentialIssuerNameLabel?.text = package.DCCIssuerName
        
        fullNameLabel?.text = package.DCCRecipientFullName
        dobValueLabel?.text = package.DCCRecipientDOB
        dobLabel?.isHidden = (package.DCCRecipientDOB?.isEmpty ?? true)

        credentialSpecLabel?.text = package.type.displayValue
       
        credentialIssuerImageView?.image = nil
       
        credentialView?.primaryColor = package.DCCColor

        credentialView?.primaryColor = package.DCCColor
    }
    
    private func addToWallet() {
        guard let package = package else {
            //TODO: error handling
            return
        }
        
        cancelBarButtonItem?.isEnabled = false
        addBarButtonItem?.isEnabled = false
        
        DataStore.shared.savePackage(package) { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.showConfirmationToast()
                self.generateNotificationFeedback(.success)
                
                DataStore.shared.loadUserData()
            }
        }
    }
    
    private func fetchSchema() {
        guard let type = verifiableObject?.type, (type == .IDHP || type == .GHP || type == .VC) else {
            self.handleVerifcationError()
            return
        }
        
        guard let credential = verifiableObject?.credential, let schemaId = credential.credentialSchema?.id else {
            self.handleVerifcationError()
            return
        }
        
        enableView(false)
        
        //Check local cache
        guard !checkSchemaCache(for: credential) else {
            return
        }
        
        SchemaService().getSchema(schemaId: schemaId) { result in
            
            switch result {
            case let .success(data):
                guard let payload = data["payload"] as? [String : Any], !(payload.isEmpty) else {
                    self.handleVerifcationError()
                    return
                }
                
                self.handleSchemaResponse(payload)
                
            case let .failure(error):
                self.handleVerifcationError(error)
            }
        }
    }
    
    private func checkSchemaCache(for credential: Credential) -> Bool {
        guard let schema = DataStore.shared.getSchema(for: credential) else {
            return false
        }
        
        self.schema = schema
        return true
    }
    
    private func handleSchemaResponse(_ schemaPayload: [String : Any]) {
        let schema = Schema(value: schemaPayload)
        DataStore.shared.addNewSchema(schema: schema)
        self.schema = schema
    }
    
    private func fetchIssuerMetadata() {
        guard let type = verifiableObject?.type, (type == .IDHP || type == .GHP || type == .VC), let credential = verifiableObject?.credential else {
            return
        }
        
        guard let issuerId = credential.issuer else {
            self.handleVerifcationError()
            return
        }
        
        enableView(false)
        
        //Check local cache
        guard !checkIssuerMetadataCache(for: credential) else {
            self.checkExisting()
            return
        }
        
        IssuerService().getIssuerMetadata(issuerId: issuerId) { result in
            switch result {
            case let .success(data):
                guard let payload = data["payload"] as? [String : Any], !(payload.isEmpty) else {
                    self.handleVerifcationError()
                    return
                }
                
                self.handleIssuerMetadataResponse(payload)
                
            case .failure(_):
                break
            }
            
            self.checkExisting()
        }
    }
    
    private func checkIssuerMetadataCache(for credential: Credential) -> Bool {
        guard let issuerMetadata = DataStore.shared.getIssuerMetadata(for: credential) else {
            return false
        }
        
        self.issuerMetadata = issuerMetadata
        return true
    }
    
    private func handleIssuerMetadataResponse(_ issuerMetadataPayload: [String : Any]) {
        let issuerMetadata = IssuerMetadata(value: issuerMetadataPayload)
        DataStore.shared.addNewIssuerMetadata(issuerMetadata: issuerMetadata)
        self.issuerMetadata = issuerMetadata
    }
    
    private func checkExisting() {
        guard let package = package else {
            existingPackage = nil
            return
        }
        
        if package.type == .VC || package.type == .IDHP || package.type == .GHP, let credentialId = package.credential?.id {
            existingPackage = DataStore.shared.getPackage(for: credentialId)
        } else if package.type == .SHC, let jws = package.jws {
            existingPackage = DataStore.shared.getPackage(for: jws)
        } else if package.type == .DCC,
                  let cose = package.cose, let cwt = CWT(from: cose.payload),
                  let certificateIdentifier = cwt.euHealthCert?.vaccinations?.first?.certificateIdentifier ?? cwt.euHealthCert?.recovery?.first?.certificateIdentifier ?? cwt.euHealthCert?.tests?.first?.certificateIdentifier {
            existingPackage = DataStore.shared.getDCCPackage(for: certificateIdentifier)
        } else {
            existingPackage = nil
        }
        
    }
    
    private func enableView(_ flag: Bool = true) {
        cancelBarButtonItem?.isEnabled = flag
        addBarButtonItem?.isEnabled = flag
        
        placeholderView?.isHidden = flag
        credentialView?.isHidden = !flag
        
        updateViewConstraints()
        view.layoutIfNeeded()
    }
    
    private func handleVerifcationError(_ error: Error? = nil) {
        enableView(false)
        credentialView?.isHidden = true
        
        let errorTitle = "wallet.verification.title".localized
        var errorMessage = "scan.verification.errorMessage".localized
        
        if let err = error as NSError? {
            let domain = err.domain.isEmpty ? "Domain=Unknown" : "Domain=\(err.domain)"
            let code = "Code=\(err.code)"
            
            errorMessage = errorMessage + String("\n\n(\(domain) | \(code))")
        }
        
        generateNotificationFeedback(.error)
        showConfirmation(title: errorTitle, message: errorMessage, actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)]) { _ in
            self.generateSelectionFeedback()
            self.package = nil
            self.performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
        }
        
    }
    
    private let toast = Toast()
    
    private func showConfirmationToast() {
        toast.label.text = "scan.verification.success".localized
        toast.glyph.image = UIImage(systemName: "wallet.pass")
        
        toast.layer.setValue("0.01", forKeyPath: "transform.scale")
        toast.alpha = 0
        view.addSubview(toast)
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: [.beginFromCurrentState], animations: {
            self.toast.alpha = 1
            UIAccessibility.post(notification: .screenChanged, argument: self.toast.label)
            self.toast.layer.setValue(1, forKeyPath: "transform.scale")
        }) { (completion) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.beginFromCurrentState], animations: {
                    self.toast.alpha = 0
                    self.toast.layer.setValue(0.8, forKeyPath: "transform.scale")
                }) { (completion) in
                    self.performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
                }
            }
        }
    }
    
    private func updateNewTextColor(for backgroundColor: UIColor) {
        let isDarkColor = backgroundColor.isDarkColor
        credentialActivityIndicatorView?.tintColor = isDarkColor ? .white : .black
        credentialSpecLabel?.textColor = isDarkColor ? .white : .black
        credentialIssuerNameLabel?.textColor = isDarkColor ? .white : .black
        credentialSchemaNameLabel?.textColor = isDarkColor ? .white : .black
        fullNameLabel?.textColor = isDarkColor ? .white : .black
        dobLabel?.textColor = isDarkColor ? .white : .black
        dobValueLabel?.textColor = isDarkColor ? .white : .black
    }
    
    private func updateExistingTextColor(for backgroundColor: UIColor) {
        let isDarkColor = backgroundColor.isDarkColor
        existingCredentialActivityIndicatorView?.tintColor = isDarkColor ? .white : .black
        existingCredentialSpecLabel?.textColor = isDarkColor ? .white : .black
        existingCredentialIssuerNameLabel?.textColor = isDarkColor ? .white : .black
        existingCredentialSchemaNameLabel?.textColor = isDarkColor ? .white : .black
        existingFullNameLabel?.textColor = isDarkColor ? .white : .black
        existingDOBLabel?.textColor = isDarkColor ? .white : .black
        existingDOBValueLabel?.textColor = isDarkColor ? .white : .black
    }
    
}
