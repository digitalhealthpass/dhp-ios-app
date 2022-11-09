//
//  ResultTableViewController.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import VerifiableCredential
import VerificationEngine

class ResultCredentialTableViewController: UITableViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorColor = UIColor(white: 0.85, alpha: 1.0)
        tableView.tableFooterView = UIView()
    }
    
    // MARK: - IBAction
    
    @IBAction func onDone(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var credential: Credential? {
        didSet {
            validateCredential()
            verifyCredential()
        }
    }

    internal var validityCheck: (Bool, String)? {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView?.reloadData()
            }
        }
    }
    
    internal var expiryCheck: (Bool?, String)? {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView?.reloadData()
            }
        }
    }
    
    internal var signatureCheck: (Bool?, String)? {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView?.reloadData()
            }
        }
    }
    
    internal var revokeCheck: (Bool?, String)? {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView?.reloadData()
            }
        }
    }
    
    internal var numberOfSections = 2
    
    internal let loadingImage = UIImage(systemName: "clock")
        
    internal let successImage = UIImage(systemName: "checkmark.circle.fill")
    internal let failImage = UIImage(systemName: "multiply.circle.fill")
    internal let warningImage = UIImage(systemName: "exclamationmark.circle.fill")

    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods
    
}

extension ResultCredentialTableViewController {
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods
    
    private func validateCredential() {
        guard let credential = credential else {
            self.validityCheck = (false, "result.invalidCredential".localized)
            return
        }
        
        CredentialVerifier().verifyCredential(credential: credential)
            .done { result in
                self.validityCheck = (true, result)
            }
            .catch { error in
                self.validityCheck = (false, error.localizedDescription)
            }
    }
    
    private func verifyCredential() {
        guard let credential = credential else {
            self.expiryCheck = (true, "result.invalidCredential".localized)
            self.signatureCheck = (false, "result.invalidCredential".localized)
            self.revokeCheck = (true, "result.invalidCredential".localized)
            return
        }
        
        //Expiration Verification
        VerifyEngine().checkExpiry(for: credential)
            .done { result in
                self.expiryCheck = result
            }
            .catch { error in
                self.expiryCheck = (true, error.localizedDescription)
            }
        
        //Signature Verification
        CredentialVerifier().checkSignature(for: credential)
            .done { result in
                self.signatureCheck = result
            }
            .catch { error in
                self.signatureCheck = (false, error.localizedDescription)
            }
        
        //Revocation Verification
        CredentialVerifier().checkRevoke(for: credential)
            .done { result in
                self.revokeCheck = result
            }
            .catch { error in
                self.revokeCheck = (true, error.localizedDescription)
            }
    }
    
}
