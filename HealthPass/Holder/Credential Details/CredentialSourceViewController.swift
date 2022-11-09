//
//  CredentialSourceViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class CredentialSourceViewController: UIViewController {
    
    var package: Package?
    
    @IBOutlet weak var credentialSourceTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        credentialSourceTextView.font = AppFont.bodyScaled
        
        updateTextView()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didRefreshKeychain(notification:)),
                                               name: ProfileTableViewController.RefreshKeychainIdentifier,
                                               object: nil)
    }
    
    @objc
    func didRefreshKeychain(notification: Notification) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func onClose(_ sender: Any) {
        generateImpactFeedback()
        
        dismiss(animated: true, completion: nil)
    }
    
    private func updateTextView() {
        let credentialType = package?.verifiableObject?.type ?? .unknown
        var payload: [String: Any]?
        
        switch credentialType {
        case .VC, .IDHP, .GHP:
            payload = package?.credential?.extendedCredentialSubject?.rawDictionary
            
        case .SHC:
            payload = package?.verifiableObject?.jws?.payload?.vc?.credentialSubject
            
        case .DCC:
            payload = package?.verifiableObject?.payload as? [String: Any]
            
        default:
            break
        }
        
        guard let payload = payload else {
            return
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]) else {
            return
        }
        
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        credentialSourceTextView.text = jsonString.replacingOccurrences(of: "\\", with: "")
    }
    
}
