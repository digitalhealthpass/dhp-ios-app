//
//  OrganizationCodeViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class OrganizationCodeViewController: UIViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        organizationCodeTextField?.text = orgId
        organizationCodeTextField?.becomeFirstResponder()
        organizationCodeTextField?.addTarget(self, action: #selector(RegistrationCodeViewController.textFieldDidChange(_:)), for: .editingChanged)
        organizationCodeTextField?.delegate = self
        
        enableKeyboardDismissGesture()
        setupView()
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var organizationCodeTextField: UITextField!
    
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var activityIndicatorView: UIView?
    
    // MARK: - IBAction
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onNext(_ sender: Any) {
        fetchDisplaySchema()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let userAgreementViewController = segue.destination as? UserAgreementViewController {
            if let orgId = sender as? String {
                userAgreementViewController.orgId = orgId
            }
            if let registrationCode = registrationCode {
                userAgreementViewController.registrationCode = registrationCode
            }
        }
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var registrationCode: String?
    
    var orgId = String() {
        didSet {
            setupView()
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let showUserAgreementSegue = "showUserAgreement"
    
    // MARK: Private Methods
    
    private func fetchDisplaySchema() {
        activityIndicatorView?.isHidden = false
        DataSubmissionService().getDisplaySchema(for: orgId) { result in
            self.activityIndicatorView?.isHidden = true
            switch result {
            case let .success(data):
                guard let payload = data["payload"] as? String, !(payload.isEmpty) else {
                    return
                }
                
                self.performSegue(withIdentifier: self.showUserAgreementSegue, sender: self.orgId)
                
            case let .failure(error):
                print(error.localizedDescription)
                self.handleError(error: error,
                                 errorTitle: "reg.failed.title".localized,
                                 errorMessage: "reg.failed.org.message".localized,
                                 errorAction: "reg.editOrgCode".localized) {
                    self.organizationCodeTextField?.becomeFirstResponder()
                    
                }
            }
        }
    }
    
    private func setupView() {
        nextButton?.isEnabled = !(orgId.isEmpty)
        nextButton?.isUserInteractionEnabled = !(orgId.isEmpty)
        let backgroundColor  = !(orgId.isEmpty) ? UIColor.systemBlue : UIColor.systemGray
        nextButton?.backgroundColor = backgroundColor
        nextButton.titleLabel?.adjustsFontSizeToFitWidth = true
    }
    
    private func enableKeyboardDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tap)
    }
    
    @objc
    private func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        view.endEditing(true)
    }
    
}

extension OrganizationCodeViewController: UITextFieldDelegate {
    
    // ======================================================================
    // === UITextFieldDelegate ==============================================
    // ======================================================================
    
    // MARK: - UITextFieldDelegate
    
    @objc
    func textFieldDidChange(_ textField: UITextField) {
        orgId = textField.text ?? String()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if !(orgId.isEmpty) {
            fetchDisplaySchema()
            return true
        }
        
        return false
    }
    
}

