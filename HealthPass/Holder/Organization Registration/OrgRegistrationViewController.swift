//
//  OrgRegistrationViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class OrgRegistrationViewController: UIViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        orgCodeTextField?.font = AppFont.bodyScaled
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
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var orgCodeTextField: UITextField?
    @IBOutlet weak var detailsTextField: UILabel!
    @IBOutlet weak var activityIndicatorView: UIView?
    @IBOutlet weak var nextButton: UIButton?
    
    // MARK: - IBAction
    
    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onNext(_ sender: UIButton) {
        org = orgCodeTextField?.text
        updateView()
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var org: String? {
        didSet {
            updateNextButton()
        }
    }
    
    var registrationCode: String?
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let orgRegistrationCodeViewController = segue.destination as? OrgRegistrationCodeViewController {
            if let registrationCode = registrationCode {
                orgRegistrationCodeViewController.registrationCode = registrationCode
                orgRegistrationCodeViewController.didDeepLink = true
            } else if org == DataStore.shared.IBM_RTO_ORG_PROD {
                orgRegistrationCodeViewController.registrationCode = DataStore.shared.IBM_RTO_REG_CODE_PROD
                orgRegistrationCodeViewController.didDeepLink = false
            }
            orgRegistrationCodeViewController.config = config
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let hitRegistrationCodeSegue = "orgRegistrationCodeSegue"
    private var config: OrgRegConfig?
    
    // MARK: Private Methods
    
    private func updateNextButton() {
        let orgCode = self.org ?? String()
        nextButton?.isEnabled = !(orgCode.isEmpty)
        nextButton?.isUserInteractionEnabled = !(orgCode.isEmpty)
        
        let backgroundColor  = !(orgCode.isEmpty) ? UIColor.systemBlue : UIColor.systemGray
        nextButton?.backgroundColor = backgroundColor
    }
    
    private func updateView() {
        self.view.isUserInteractionEnabled = true
        activityIndicatorView?.isHidden = true
        
        activityIndicatorView?.layer.borderColor = UIColor.systemBlue.cgColor
        activityIndicatorView?.layer.shadowColor = UIColor.black.cgColor
        
        if let org = self.org {
            fetchOrgRegConfig(for: org)
        } else {
            orgCodeTextField?.becomeFirstResponder()
        }
        
        orgCodeTextField?.text = org
        orgCodeTextField?.addTarget(self, action: #selector(OrgRegistrationViewController.textFieldDidChange(_:)), for: .editingChanged)
        orgCodeTextField?.delegate = self
        
        orgCodeTextField?.layer.borderColor = UIColor.systemBlue.cgColor
        
        enableKeyboardDismissGesture()
    }
    
    private func enableKeyboardDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tap)
    }
    
    @objc
    private func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        view.endEditing(true)
    }
    
    private func fetchOrgRegConfig(for org: String) {
        orgCodeTextField?.resignFirstResponder()
        
        self.view.isUserInteractionEnabled = false
        self.activityIndicatorView?.isHidden = false
        
        DataSubmissionService().getRegistrationConfig(for: org) { result in
            switch result {
            case let .success(json):
                guard let payload = json["payload"] as? [String : Any], !(payload.isEmpty) else {
                    self.handleRegistrationError()
                    return
                }
                
                self.config = OrgRegConfig(value: payload)
                self.performSegue(withIdentifier: self.hitRegistrationCodeSegue, sender: nil)
                
            case let .failure(error):
                self.handleRegistrationError(error: error)
            }
            
            self.view.isUserInteractionEnabled = true
            self.activityIndicatorView?.isHidden = true
        }
    }
    
    private func handleRegistrationError(error: Error? = nil) {
        let title = "reg.failed.title".localized
        var message = "reg.failed.org.message".localized
        
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
                self.org = nil
                self.updateView()
            }
        }
    }
}

extension OrgRegistrationViewController: UITextFieldDelegate {
    // ======================================================================
    // === UISearchTextFieldDelegate ==============================================
    // ======================================================================
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        org = orgCodeTextField?.text
        updateView()
        
        textField.resignFirstResponder()
        
        return true
    }
    
    @objc
    func textFieldDidChange(_ textField: UITextField) {
        org = textField.text ?? String()
    }
}
