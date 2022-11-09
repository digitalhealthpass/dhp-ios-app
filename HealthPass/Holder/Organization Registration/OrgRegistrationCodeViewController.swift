//
//  OrgRegistrationCodeViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import Alamofire
import Foundation

class OrgRegistrationCodeViewController: UIViewController, OrgRegistrable {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registrationCodeTextField?.font = AppFont.bodyScaled
        detailsTextField.font = AppFont.calloutScaled
        nextButton?.titleLabel?.font = AppFont.headlineScaled

        updateView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
      
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if didDeepLink {
            didDeepLink = false
            
            registrationCode = registrationCodeTextField?.text
            registerCode()
        }
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var registrationCodeTextField: UITextField?
    @IBOutlet weak var detailsTextField: UILabel!
    @IBOutlet weak var activityIndicatorView: UIView?
    @IBOutlet weak var nextButton: UIButton?
    
    // MARK: - IBAction
    
    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onNext(_ sender: UIButton) {
        registrationCode = registrationCodeTextField?.text
        registerCode()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let orgVerificationCodeViewController = segue.destination as? OrgVerificationCodeViewController {
            orgVerificationCodeViewController.registrationCode = registrationCode
            orgVerificationCodeViewController.config = config
        } else if let orgUserAgreementViewController = segue.destination as? OrgUserAgreementViewController {
            orgUserAgreementViewController.config = config
            orgUserAgreementViewController.registrationCode = registrationCode
        } else if let registrationDetailsViewController = segue.destination as? RegistrationDetailsViewController,
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
    var didDeepLink: Bool = false
    
    var registrationCode: String? {
        didSet {
            updateNextButton()
        }
    }
    
    var config: OrgRegConfig?
    var verificationCode: String?
    var contactTuple: (Credential, Credential)?
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let verificationCodeSegue = "verificationCodeSegue"
    private let userAgreementSegue = "userAgreementSegue"
    private let registrationFormSegue = "registrationFormSegue"
    
    // MARK: Private Methods
    
    private func updateView() {
        self.view.isUserInteractionEnabled = true
        activityIndicatorView?.isHidden = true
        
        activityIndicatorView?.layer.borderColor = UIColor.systemBlue.cgColor
        activityIndicatorView?.layer.shadowColor = UIColor.black.cgColor
        
        registrationCodeTextField?.text = registrationCode
        registrationCodeTextField?.becomeFirstResponder()
        registrationCodeTextField?.addTarget(self, action: #selector(OrgRegistrationCodeViewController.textFieldDidChange(_:)), for: .editingChanged)
        registrationCodeTextField?.delegate = self
        
        registrationCodeTextField?.layer.borderColor = UIColor.systemBlue.cgColor
        
        enableKeyboardDismissGesture()
        
        updateNextButton()
    }
    
    private func enableKeyboardDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tap)
    }
    
    @objc
    private func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        view.endEditing(true)
    }
    
    private func handleFlow() {
        let flow = self.config?.flow
        if flow?.mfaAuth ?? false {
            self.performSegue(withIdentifier: self.verificationCodeSegue, sender: nil)
        } else if flow?.showUserAgreement ?? false {
            self.performSegue(withIdentifier: self.userAgreementSegue, sender: nil)
        } else if flow?.showRegistrationForm ?? false, let registrationForm = config?.registrationForm {
            let orgSchema = Schema(value: ["schema": ["properties": registrationForm]])
            self.performSegue(withIdentifier: self.registrationFormSegue, sender: orgSchema)
        } else {
            submitRegistration()
        }
    }
    
    private func registerCode() {
        registrationCodeTextField?.resignFirstResponder()
        
        guard let organizationCode = config?.org,
              let registrationCode = registrationCodeTextField?.text else {
            self.handleRegistrationError()
            return
        }
        
        self.view.isUserInteractionEnabled = false
        activityIndicatorView?.isHidden = false
        
        let registrationCodeCompletion: ((Result<[String: Any]>) -> Void)? = { result in
            switch result {
            case let .success(json):
                self.verificationCode = json["verificationCode"] as? String
                self.handleFlow()
                
            case let .failure(error):
                self.handleRegistrationError(error: error)
            }
            
            self.view.isUserInteractionEnabled = true
            self.activityIndicatorView?.isHidden = true
        }
        
        if let flow = self.config?.flow, flow.mfaAuth {
            DataSubmissionService().registerMFA(for: organizationCode, with: registrationCode, completion: registrationCodeCompletion)
        } else {
            DataSubmissionService().validateCode(for: organizationCode, and: registrationCode, completion: registrationCodeCompletion)
        }
        
    }
    
    private func submitRegistration() {
        guard let organizationCode = config?.org,
              let registrationCode = registrationCodeTextField?.text else {
            self.handleRegistrationError()
            return
        }
        
        self.view.isUserInteractionEnabled = false
        activityIndicatorView?.isHidden = false
        
        DataSubmissionService().submitMFA(for: organizationCode, with: registrationCode) { result in
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
    }
    
    private func updateNextButton() {
        let registrationCode = self.registrationCode ?? String()
        let backgroundColor  = !(registrationCode.isEmpty) ? UIColor.systemBlue : UIColor.systemGray
        
        nextButton?.isEnabled = !(registrationCode.isEmpty)
        nextButton?.isUserInteractionEnabled = !(registrationCode.isEmpty)
        nextButton?.backgroundColor = backgroundColor
    }
    
    private func handleRegistrationError(error: Error? = nil) {
        let title = "reg.failed.title".localized
        var message = "reg.failed.rcode.message".localized
        
        if let err = error as NSError? {
            let domain = err.domain.isEmpty ? "Domain=Unknown" : "Domain=\(err.domain)"
            let code = "Code=\(err.code)"
            
            message = message + String("\n\n(\(domain) | \(code))")
        }

        self.showConfirmation(title: title,
                              message: message,
                              actions: [("reg.exit".localized, IBMAlertActionStyle.destructive), ("reg.editCode".localized, IBMAlertActionStyle.default)]) { index in
            if index == 0 {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.registrationCodeTextField?.becomeFirstResponder()
            }
        }
    }
    
}

extension OrgRegistrationCodeViewController: UITextFieldDelegate {
    // ======================================================================
    // === UISearchTextFieldDelegate ==============================================
    // ======================================================================
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        registrationCode = textField.text
        registerCode()
        
        textField.resignFirstResponder()
        
        return true
    }
    
    @objc
    func textFieldDidChange(_ textField: UITextField) {
        registrationCode = textField.text ?? String()
    }
}
