//
//  UserAgreementViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class UserAgreementViewController: UIViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        termsConditionsButton.titleLabel?.numberOfLines = 0
        termsConditionsButton.titleLabel?.adjustsFontSizeToFitWidth = true
        termsConditionsButton.titleLabel?.lineBreakMode = .byWordWrapping
        nextButton.titleLabel?.adjustsFontSizeToFitWidth = true
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        if let text = termsConditionsButton.titleLabel?.text, let font = termsConditionsButton.titleLabel?.font {
            termsConditionsButtonHeightConstraint.constant = text.height(withConstrainedWidth: termsConditionsButton.frame.width, font: font)
        }
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var termsConditionsButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var termsConditionsButtonHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var activityIndicatorView: UIView?
    
    // MARK: - IBAction
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onTermsConditions(_ sender: Any) {
        acceptedTermsConditions = !acceptedTermsConditions
    }
    
    @IBAction func onNext(_ sender: Any) {
        fetchDisplaySchema()
    }
    
    // MARK: - Navigation
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let registrationCodeViewController = segue.destination as? RegistrationCodeViewController {
            if let orgId = orgId {
                registrationCodeViewController.orgId = orgId
            }
            if let orgSchema = orgSchema {
                registrationCodeViewController.orgSchema = orgSchema
            }
            if let registrationCode = registrationCode {
                registrationCodeViewController.registrationCode = registrationCode
            }
        }
    }
    
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var registrationCode: String?
    
    var orgId: String?
    
    var orgSchema: Schema?
    
    var schemaID: String? {
        didSet {
            fetchSchema()
        }
    }
    
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let showRegistrationCodeSegue = "showRegistrationCode"
    
    private var acceptedTermsConditions = false {
        didSet {
            let imageName = acceptedTermsConditions ? "checkmark.square.fill" : "square"
            termsConditionsButton.setImage(UIImage(systemName: imageName), for: .normal)
            
            nextButton.isEnabled = acceptedTermsConditions
            nextButton.isUserInteractionEnabled = acceptedTermsConditions
            let backgroundColor = acceptedTermsConditions ? UIColor.systemBlue : UIColor.systemGray
            nextButton.backgroundColor = backgroundColor
        }
    }
    
    // MARK: Private Methods
    
    private func fetchDisplaySchema() {
        guard let orgId = orgId else {
            return
        }
        
        activityIndicatorView?.isHidden = false
        DataSubmissionService().getDisplaySchema(for: orgId) { result in
            self.activityIndicatorView?.isHidden = true
            switch result {
            case let .success(data):
                guard let payload = data["payload"] as? String, !(payload.isEmpty) else {
                    return
                }
                
                self.schemaID = payload
                
            case let .failure(error):
                print(error.localizedDescription)
                self.handleError(error: error, errorTitle: "reg.failed".localized) {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    private func fetchSchema() {
        if let _ = orgSchema {
            return
        }
        
        guard let schemaID = self.schemaID else {
            return
        }
        
        //Check local cache
        guard !checkSchemaCache(for: schemaID) else { return }

        activityIndicatorView?.isHidden = false
        SchemaService().getSchema(schemaId: schemaID) { result in
            self.activityIndicatorView?.isHidden = true
            switch result {
            case let .success(data):
                guard let payload = data["payload"] as? [String : Any], !(payload.isEmpty) else {
                    return
                }
                
                self.orgSchema = Schema(value: payload)
                self.performSegue(withIdentifier: self.showRegistrationCodeSegue, sender: nil)
                
            case let .failure(error):
                print(error.localizedDescription)
                self.handleError(error: error,
                                 errorTitle: "reg.failed.title".localized,
                                 errorMessage: "reg.failed.org.message".localized,
                                 errorAction: "reg.editOrgCode".localized) {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    private func checkSchemaCache(for schemaID: String) -> Bool {
        guard let schema = DataStore.shared.getSchema(for: schemaID) else {
            return false
        }
        
        self.orgSchema = schema
        self.performSegue(withIdentifier: self.showRegistrationCodeSegue, sender: nil)
        return true
    }
}
