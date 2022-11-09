//
//  OrgVerificationCodeViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class OrgVerificationCodeViewController: UIViewController, OrgRegistrable {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        verificationCodeTextField?.font = AppFont.bodyScaled
        detailsTextField.font = AppFont.calloutScaled
        nextButton?.titleLabel?.font = AppFont.headlineScaled
        resendButton?.titleLabel?.font = AppFont.bodyScaled

        updateView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
      
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer.invalidate()
        resendButton?.isUserInteractionEnabled = true
        resendButton?.setTitleColor(.systemBlue, for: .normal)
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var verificationCodeTextField: UITextField?
    @IBOutlet weak var detailsTextField: UILabel!
    @IBOutlet weak var nextButton: UIButton?
    @IBOutlet weak var resendButton: UIButton?
    @IBOutlet weak var activityIndicatorView: UIView?
    @IBOutlet weak var timerLabel: UILabel?
    
    // MARK: - IBAction
    
    @IBAction func onResend(_ sender: UIButton) {
        registerCode()
    }
    
    @IBAction func onNext(_ sender: UIButton) {
        verifyCode()
    }
    
    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let orgUserAgreementViewController = segue.destination as? OrgUserAgreementViewController {
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
    
    var verificationCode: String? {
        didSet {
            updateNextButton()
        }
    }
    
    var config: OrgRegConfig?
    var registrationCode: String?
    var contactTuple: (Credential, Credential)?
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let userAgreementSegue = "userAgreementFromVerificationSegue"
    private let registrationFormSegue = "registrationFormSegue"

    private var countdown = 31
    private var timer = Timer()
    private var isTimerRunning = false
    
    // MARK: Private Methods
    
    private func updateView() {
        self.view.isUserInteractionEnabled = true
        activityIndicatorView?.isHidden = true
        
        activityIndicatorView?.layer.borderColor = UIColor.systemBlue.cgColor
        activityIndicatorView?.layer.shadowColor = UIColor.black.cgColor
        
        runTimer()
        
        verificationCodeTextField?.textContentType = .oneTimeCode
        
        verificationCodeTextField?.text = verificationCode
        verificationCodeTextField?.becomeFirstResponder()
        verificationCodeTextField?.addTarget(self, action: #selector(OrgVerificationCodeViewController.textFieldDidChange(_:)), for: .editingChanged)
        verificationCodeTextField?.delegate = self
        
        verificationCodeTextField?.layer.borderColor = UIColor.systemBlue.cgColor
        
        enableKeyboardDismissGesture()
        
        updateNextButton()
    }
    
    private func runTimer() {
        resendButton?.isUserInteractionEnabled = false
        resendButton?.setTitleColor(.systemGray, for: .normal)
        timerLabel?.isHidden = false
        
        countdown = 301
        
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: (#selector(OrgVerificationCodeViewController.updateTimer)),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    private func timeString(time: TimeInterval) -> String {
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i", minutes, seconds)
    }
    
    @objc
    private func updateTimer() {
        if countdown < 1 {
            timer.invalidate()
            resendButton?.isUserInteractionEnabled = true
            resendButton?.setTitleColor(.systemBlue, for: .normal)
            
            timerLabel?.isHidden = true
        } else {
            countdown -= 1
            timerLabel?.text = timeString(time: TimeInterval(countdown))
        }
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
        if flow?.showUserAgreement ?? false {
            self.performSegue(withIdentifier: self.userAgreementSegue, sender: nil)
        } else if flow?.showRegistrationForm ?? false, let registrationForm = config?.registrationForm {
            let orgSchema = Schema(value: ["schema": ["properties": registrationForm]])
            self.performSegue(withIdentifier: self.registrationFormSegue, sender: orgSchema)
        } else {
            submitRegistration()
        }
    }
    
    private func verifyCode() {
        guard let organizationCode = config?.org,
              let verificationCode = verificationCodeTextField?.text else {
            self.handleRegistrationError()
            return
        }
        
        self.view.isUserInteractionEnabled = false
        activityIndicatorView?.isHidden = false
        DataSubmissionService().verifyMFA(for: organizationCode, with: verificationCode) { result in
            switch result {
            
            case let .success(json):
                self.registrationCode = json["registrationCode"] as? String
                self.handleFlow()
                
            case let .failure(error):
                self.handleRegistrationError(error: error)
            }
            
            self.view.isUserInteractionEnabled = true
            self.activityIndicatorView?.isHidden = true
        }
    }
    
    private func registerCode() {
        guard let organizationCode = config?.org,
              let registrationCode = registrationCode else {
            self.handleRegistrationError()
            return
        }
        
        self.view.isUserInteractionEnabled = false
        activityIndicatorView?.isHidden = false
        DataSubmissionService().registerMFA(for: organizationCode, with: registrationCode) { result in
            switch result {
            case let .success(json):
                self.verificationCode = json["verificationCode"] as? String
                self.updateView()
                
            case let .failure(error):
                self.handleRegistrationError(error: error)
            }
            
            self.view.isUserInteractionEnabled = true
            self.activityIndicatorView?.isHidden = true
        }
    }
    
    private func submitRegistration() {
        guard let organizationCode = config?.org,
              let registrationCode = registrationCode else {
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
        let registrationCode = self.verificationCode ?? String()
        nextButton?.isEnabled = !(registrationCode.isEmpty)
        nextButton?.isUserInteractionEnabled = !(registrationCode.isEmpty)
        let backgroundColor  = !(registrationCode.isEmpty) ? UIColor.systemBlue : UIColor.systemGray
        nextButton?.backgroundColor = backgroundColor
    }
    
    private func handleRegistrationError(error: Error? = nil) {
        let title = "reg.failed.title".localized
        var message = "reg.failed.vcode.message".localized
        
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
                self.verificationCodeTextField?.becomeFirstResponder()
            }
        }
    }
}

extension OrgVerificationCodeViewController: UITextFieldDelegate {
    // ======================================================================
    // === UISearchTextFieldDelegate ==============================================
    // ======================================================================
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    @objc
    func textFieldDidChange(_ textField: UITextField) {
        verificationCode = textField.text ?? String()
    }
}
