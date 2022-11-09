//
//  RegistrationCodeViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class RegistrationCodeViewController: UIViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registrationCodeTextField?.text = registrationCode
        registrationCodeTextField?.becomeFirstResponder()
        registrationCodeTextField?.addTarget(self, action: #selector(RegistrationCodeViewController.textFieldDidChange(_:)), for: .editingChanged)
        registrationCodeTextField?.delegate = self
        
        enableKeyboardDismissGesture()
        setupView()
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var registrationCodeTextField: UITextField!
    
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var activityIndicatorView: UIView?
    
    // MARK: - IBAction
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onNext(_ sender: Any) {
        validateRegistrationCode()
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let registrationDetailsViewController = segue.destination as? RegistrationDetailsViewController {
            registrationDetailsViewController.orgId = orgId
            registrationDetailsViewController.orgSchema = orgSchema
            registrationDetailsViewController.registrationCode = registrationCode
        }
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var orgId: String?
    var orgSchema: Schema?
    
    var registrationCode = String() {
        didSet {
            setupView()
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let showRegistrationFormSegue = "showRegistrationForm"
    
    // MARK: Private Methods
    
    private func setupView() {
        nextButton?.isEnabled = !(registrationCode.isEmpty)
        nextButton?.isUserInteractionEnabled = !(registrationCode.isEmpty)
        let backgroundColor  = !(registrationCode.isEmpty) ? UIColor.systemBlue : UIColor.systemGray
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
    
    private func validateRegistrationCode() {
        guard let orgId = orgId else {
            return
        }
        
        activityIndicatorView?.isHidden = false
        view.isUserInteractionEnabled = false
        
        DataSubmissionService().validateCode(for: orgId, and: registrationCode) { result in
            self.activityIndicatorView?.isHidden = true
            self.view.isUserInteractionEnabled = true
            
            switch result {
            case .success:
                self.performSegue(withIdentifier: self.showRegistrationFormSegue, sender: nil)
                
            case let .failure(error):
                self.handleError(error: error,
                                 errorTitle: "reg.failed.title".localized,
                                 errorMessage: "reg.failed.rcode.message".localized,
                                 errorAction: "reg.editCode".localized) {
                    self.registrationCodeTextField.becomeFirstResponder()
                }
            }
        }
    }
}

extension RegistrationCodeViewController: UITextFieldDelegate {
    
    // ======================================================================
    // === UITextFieldDelegate ==============================================
    // ======================================================================
    
    // MARK: - UITextFieldDelegate
    
    @objc
    func textFieldDidChange(_ textField: UITextField) {
        registrationCode = textField.text ?? String()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if !(registrationCode.isEmpty) {
            validateRegistrationCode()
            return true
        }
        
        return false
    }
}
