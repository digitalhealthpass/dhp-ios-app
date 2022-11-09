//
//  ResultJWSTableViewController.swift
//  Verifier
//
//  Created by Gautham Velappan on 6/13/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import VerifiableCredential
import VerificationEngine

class ResultJWSTableViewController: UITableViewController {

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

    internal var jws: JWS? {
        didSet {
            validateJWS()
            verifyJWS()
        }
    }

    internal var validityCheck: (Bool, String)? {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView?.reloadData()
            }
        }
    }

    internal var trustedIssuerCheck: (Bool?, String)? {
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

    internal var numberOfSections = 2 
    internal let loadingImage = UIImage(systemName: "clock")
        
    internal let successImage = UIImage(systemName: "checkmark.circle.fill")
    internal let failImage = UIImage(systemName: "multiply.circle.fill")
    internal let warningImage = UIImage(systemName: "exclamationmark.circle.fill")

    internal let showFHIRDetailsSegue = "showFHIRDetails"

    // ======================================================================
    // MARK: - Private
    // ======================================================================
  
    // MARK: Private Properties
    
    // MARK: Private Methods
    
}

extension ResultJWSTableViewController {
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods

    private func validateJWS() {
        guard let jws = jws else {
            self.validityCheck = (false, "result.invalidCredential".localized)
            return
        }
        
        CredentialVerifier().verifyJWS(jws: jws)
            .done { result in
                self.validityCheck = (true, result)
            }
            .catch { error in
                self.validityCheck = (false, error.localizedDescription)
            }
    }

    private func verifyJWS() {
        guard let jws = jws else {
            self.expiryCheck = (true, "result.invalidCredential".localized)
            self.signatureCheck = (false, "result.invalidCredential".localized)
            return
        }
        
        //Expiration Verification
        CredentialVerifier().checkIssuerURLTrusted(for: jws)
            .done { result in
                self.trustedIssuerCheck = (result, String())
            }
            .catch { error in
                self.trustedIssuerCheck = (false, error.localizedDescription)
            }

        //Expiration Verification
        VerifyEngine().checkExpiry(for: jws)
            .done { result in
                self.expiryCheck = result
            }
            .catch { error in
                self.expiryCheck = (true, error.localizedDescription)
            }
        
        //Signature Verification
        CredentialVerifier().checkSignature(for: jws)
            .done { result in
                self.signatureCheck = result
            }
            .catch { error in
                self.signatureCheck = (false, error.localizedDescription)
            }
    }

}
