//
//  OrgUserAgreementViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import WebKit
import Alamofire
import Foundation

class OrgUserAgreementViewController: UIViewController, OrgRegistrable {
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        updateView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var activityIndicatorView: UIView?
    
    // MARK: - IBAction
    
    @IBAction func onDisagree(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
    }
    
    @IBAction func onAgree(_ sender: UIButton) {
        handleFlow()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let registrationDetailsViewController = segue.destination as? RegistrationDetailsViewController,
           let orgSchema = sender as? Schema {
            registrationDetailsViewController.orgSchema = orgSchema
            registrationDetailsViewController.orgId = config?.org
            registrationDetailsViewController.registrationCode = registrationCode
        }
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var config: OrgRegConfig?
    var registrationCode: String?
    var contactTuple: (Credential, Credential)?
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let registrationFormSegue = "registrationFormSegue"
    
    private let unwindToWalletSegue = "unwindToWallet"
    
    private var dataSourceValue = [String: Any]()
    
    private var generatedKeyPair: [String: Any?]? {
        didSet {
            updateViewForKey()
        }
    }
    
    private var didFinishLoading = false
    
    private var tag: String?
    private var date: Date?
    
    private var publickeySecString: String? {
        didSet {
            didFinishLoading = (publickeySecString != nil) && (privatekeySecString != nil)
            dataSourceValue["publicKey"] = publickeySecString
            dataSourceValue["id"] = self.publickeySecString
        }
    }
    private var publickeySecData: Data? {
        didSet {
            publickeySecString = publickeySecData?.base64EncodedString()
        }
    }
    
    private var privatekeySecString: String?{
        didSet {
            didFinishLoading = (publickeySecString != nil) && (privatekeySecString != nil)
        }
    }
    private var privatekeySecData: Data? {
        didSet {
            privatekeySecString = privatekeySecData?.base64EncodedString()
        }
    }
    
    // MARK: Private Methods
    
    private func handleFlow() {
        let flow = self.config?.flow
        if flow?.showRegistrationForm ?? false, let registrationForm = config?.registrationForm {
            let orgSchema = Schema(value: ["schema": ["properties": registrationForm]])
            self.performSegue(withIdentifier: self.registrationFormSegue, sender: orgSchema)
        } else {
            submitRegistration()
        }
    }
    private func updateView() {
        generateNewKeyPair()
        
        self.view.isUserInteractionEnabled = true
        activityIndicatorView?.isHidden = true
        
        activityIndicatorView?.layer.borderColor = UIColor.systemBlue.cgColor
        activityIndicatorView?.layer.shadowColor = UIColor.black.cgColor
        
        webView.configuration.preferences.javaScriptEnabled = true
        webView.navigationDelegate = self
        
        if let agreement = config?.userAgreement {
            var updatedUserAgreement = "<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0'></header>"
            updatedUserAgreement.append(agreement)
            webView.loadHTMLString(updatedUserAgreement, baseURL: nil)
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contentSizeDidChange(_:)),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
        
    }
    
    @objc
    private func contentSizeDidChange(_ notification: Notification) {
        webView.reload()
    }
    
    private func submitRegistration() {
        guard let organizationCode = config?.org,
              let registrationCode = registrationCode else {
                  self.handleRegistrationError()
                  return
              }
        
        self.view.isUserInteractionEnabled = false
        activityIndicatorView?.isHidden = false
        
        let submitRegistrationCompletion: ((Result<[String: Any]>) -> Void)? = { result in
            switch result {
            case .success(let data):
                guard let payload = data["payload"] as? [[String : Any]] else {
                    self.handleRegistrationError()
                    return
                }
                
                self.contactTuple = self.contactTuple(from: payload)
                self.performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
                
            case .failure(let error):
                self.handleRegistrationError(error: error)
            }
            
            self.view.isUserInteractionEnabled = true
            self.activityIndicatorView?.isHidden = true
        }
        
        if let flow = self.config?.flow, flow.mfaAuth {
            DataSubmissionService().submitMFA(for: organizationCode, with: registrationCode, completion: submitRegistrationCompletion)
        } else {
            dataSourceValue["organization"] = organizationCode
            dataSourceValue["registrationCode"] = registrationCode
            
            guard let keypairDictionary = constructDictionary() else {
                return
            }
            
            saveKeyPair(dictionary: keypairDictionary) { success in
                DataSubmissionService().register(for: organizationCode, with: self.dataSourceValue, completion: submitRegistrationCompletion)
            }
        }
    }
    
    private func showRegistrationForm() {
        // TODO: Registration Form flow should be moved to a common storyboard & registrationForm should be passed into RegistrationDetailsViewController without creating a Schema
        let vc = Storyboard.ResearchRegistration.instantiateViewController(identifier: ControllerIdentifier.View.RegistrationDetails) as RegistrationDetailsViewController
        if let registrationForm = config?.registrationForm {
            let schema = Schema(value: ["schema": ["properties": registrationForm]])
            vc.orgSchema = schema
        }
        vc.orgId = config?.org
        vc.registrationCode = registrationCode
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func handleRegistrationError(error: Error? = nil) {
        let title = "reg.failed.title".localized
        var message = "reg.failed.message".localized
        
        if let err = error as NSError? {
            let domain = err.domain.isEmpty ? "Domain=Unknown" : "Domain=\(err.domain)"
            let code = "Code=\(err.code)"
            
            message = message + String("\n\n(\(domain) | \(code))")
        }
        
        self.showConfirmation(title: title,
                              message: message,
                              actions: [("Exit", IBMAlertActionStyle.destructive), ("reg.retry".localized, IBMAlertActionStyle.default)]) { index in
            if index == 0 {
                self.performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
            } else {
                self.handleFlow()
            }
        }
    }
}

extension OrgUserAgreementViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let cssString = "@media (prefers-color-scheme: dark) {body {color: white;} p {font-size: 100%;} h3 {font-size: 100%;} a:link {color: #0096e2;}a:visited {color: #9d57df;}}"
        let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);"
        webView.evaluateJavaScript(jsString, completionHandler: nil)
    }
}

extension OrgUserAgreementViewController {
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods
    
    private func generateNewKeyPair() {
        do {
            let keyTuple = try KeyGen.generateNewKeys(tag: registrationCode)
            self.generatedKeyPair = [ "publickey": keyTuple.publickey,
                                      "privatekey": keyTuple.privatekey,
                                      "tag": registrationCode,
                                      "timestamp" : Date() ]
        } catch {
            self.generatedKeyPair = nil
            self.generateNotificationFeedback(.error)
        }
    }
    
    private func updateViewForKey() {
        var dictionary: [String : Any?]?
        
        if let generatedKeyPair = generatedKeyPair {
            dictionary = generatedKeyPair
        }
        
        if let dictionary = dictionary {
            updateTag(for: dictionary)
            updateTimestamp(for: dictionary)
            updatePublic(for: dictionary)
            updatePrivate(for: dictionary)
        }
    }
    
    private func updateTag(for dictionary: [String : Any?]) {
        if let tag = dictionary["tag"] as? String, !tag.isEmpty {
            self.tag = tag
        }
    }
    
    private func updateTimestamp(for dictionary: [String : Any?]) {
        if let date = dictionary["timestamp"] as? Date {
            self.date = date
        }
    }
    
    private func updatePublic(for dictionary: [String : Any?]) {
        if let publickey = dictionary["publickey"] {
            let publickeySec = publickey as! SecKey
            self.publickeySecData = try? KeyGen.decodeKeyToData(publickeySec)
        }
    }
    
    private func updatePrivate(for dictionary: [String : Any?]) {
        if let privatekey = dictionary["privatekey"] {
            let privatekeySec = privatekey as! SecKey
            self.privatekeySecData = try? KeyGen.decodeKeyToData(privatekeySec)
        }
    }
    
    private func constructDictionary() -> [String: Any]? {
        var dictionary = [String: Any]()
        var id = String()
        
        if let tag = tag {
            dictionary["tag"] = tag
            id = String(format: "%@.%@", id, tag)
        }
        
        if let date = date {
            dictionary["timestamp"] = Date.stringForDate(date: date, dateFormatPattern: .keyGenFormat)
            id = String(format: "%@.%@", id, Date.stringForDate(date: date, dateFormatPattern: .timestampFormat))
        }
        
        if let publickey = publickeySecString {
            dictionary["publickey"] = publickey
        }
        
        if let privatekey = privatekeySecString {
            dictionary["privatekey"] = privatekey
        }
        
        dictionary["id"] = id
        
        return dictionary
    }
    
    private func saveKeyPair(dictionary: [String : Any], completion: ((_ success: Bool) -> Void)? = nil) {
        DataStore.shared.saveKeyPair(dictionary) { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                DataStore.shared.loadUserData()
                NotificationCenter.default.post(name: ProfileTableViewController.RefreshKeychainIdentifier, object: nil)
                let success = result.isSuccess
                completion?(success)
            }
        }
    }
    
}
