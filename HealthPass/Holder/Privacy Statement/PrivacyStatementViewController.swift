//
//  PrivacyStatementViewController.swift
//  Holder
//
//  Created by Gautham Velappan on 4/27/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import WebKit

class PrivacyStatementViewController: UIViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        privacyStatementWebView.loadHTMLString("privacy.statement".localized, baseURL: nil)
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var privacyStatementWebView: WKWebView!
    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem?
    
    // MARK: - IBAction
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        guard let parent = self.presentingViewController else {
            return
        }
        
        if parent.isKind(of: LaunchViewController.self) {
            DataStore.shared.didAcceptPrivacyStatement = true
            performSegue(withIdentifier: "unwindToLaunch", sender: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
