//
//  TermsConditionsViewController.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class TermsConditionsViewController: UIViewController {
   
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        termsConditionsTextView?.font = AppFont.bodyScaled
        
        isModalInPresentation = true
     
        termsConditionsTextView?.text = "terms.conditions.verifier".localized
  
        updateNavigationDisplay()
    }
    
    // MARK: - IBOutlet

    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem?
    
    @IBOutlet weak var termsConditionsTextView: UITextView?
    
    @IBOutlet weak var agreeBarButtonItem: UIBarButtonItem?
    @IBOutlet weak var disagreeBarButtonItem: UIBarButtonItem?
    
    // MARK: - IBAction

    @IBAction func onDone(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "unwindToProfile", sender: nil)
    }

    @IBAction func onAgree(_ sender: UIBarButtonItem) {
        DataStore.shared.didAgreeTermsConditions = true
        performSegue(withIdentifier: "unwindToLaunch", sender: nil)
    }
    
    @IBAction func onDisagree(_ sender: UIBarButtonItem) {
        showConfirmation(title: "t_c.title".localized,
                         message: "t_c.message".localized,
                         actions: [("t_c.continue".localized, IBMAlertActionStyle.default), ("t_c.disagree".localized, IBMAlertActionStyle.cancel)]) { index in
            if index == 1 {
                DataStore.shared.didAgreeTermsConditions = false
                self.performSegue(withIdentifier: "unwindToLaunch", sender: nil)
            }
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods
    
    private func updateNavigationDisplay() {
        guard let parent = self.presentingViewController else { return }
        
        if parent.isKind(of: LaunchViewController.self) {
            self.navigationController?.toolbar.isHidden = false
            self.navigationItem.rightBarButtonItem = nil
        } else {
            self.navigationController?.toolbar.isHidden = true
            self.navigationController?.navigationItem.rightBarButtonItem = doneBarButtonItem
        }
    }

}
