//
//  PrivacyPolicyViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import SafariServices

class PrivacyPolicyViewController: UIViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        privacyPolicyTextView?.font = AppFont.bodyScaled
        
        privacyPolicyTextView?.delegate = self
        
#if HOLDER
        privacyPolicyTextView?.text = "privacy.policy.wallet".localized
#else
        privacyPolicyTextView?.text = "privacy.policy.verifier".localized
#endif
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var acceptButtonBar: UIBarButtonItem?
    @IBOutlet weak var privacyPolicyTextView: UITextView?
    
    // MARK: - IBAction
    
    @IBAction func onAccept(_ sender: UIBarButtonItem) {
        guard let parent = self.presentingViewController else {
            return
        }
        
        if parent.isKind(of: LaunchViewController.self) {
            DataStore.shared.didAcceptPrivacy = true
            performSegue(withIdentifier: "unwindToLaunch", sender: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
}

extension PrivacyPolicyViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let safariViewController = SFSafariViewController(url: URL)
        safariViewController.modalPresentationStyle = .pageSheet
        present(safariViewController, animated: true, completion: nil)
        
        return false
    }
    
}
