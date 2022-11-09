//
//  WalletTableViewController+FilesSHC.swift
//  Holder
//
//  Created by Gautham Velappan on 12/2/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit
import MobileCoreServices

extension WalletTableViewController {
    
    internal func showFiles() {
        let importMenu = UIDocumentPickerViewController(documentTypes: [String(kUTTypeData)], in: .import)
        importMenu.delegate = self
        
        importMenu.allowsMultipleSelection = false
        importMenu.modalPresentationStyle = .formSheet
        
        present(importMenu, animated: true, completion: nil)
    }
    
    internal func openFile(at url: URL) {
        guard let rawData = FileManager.default.contents(atPath: url.path),
              let json = try? JSONSerialization.jsonObject(with: rawData, options: []) as? [String : Any],
              let values = json["verifiableCredential"] as? [String],
              let data = values.first?.data(using: .utf8) else {
                  self.handleUnsupportedCredentials()
                  self.generateNotificationFeedback(.error)
                  return
              }
        
        self.showScanComplete(with: data)
    }
    
    private func handleUnsupportedCredentials() {
        let errorTitle = "wallet.unsupported.title".localized
        let errorMessage = "wallet.unsupported.message".localized
        
        generateNotificationFeedback(.error)
        showConfirmation(title: errorTitle, message: errorMessage, actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
    }

    
}

extension WalletTableViewController : UIDocumentPickerDelegate, UINavigationControllerDelegate {
    
    // ======================================================================
    // === UIDocumentPickerViewController ==================================
    // ======================================================================
    
    // MARK: - UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        self.openFile(at: url)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { }
}

