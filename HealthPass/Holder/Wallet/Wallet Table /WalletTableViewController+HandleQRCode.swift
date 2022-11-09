//
//  WalletTableViewController+HandleQRCode.swift
//  Holder
//
//  Created by Gautham Velappan on 12/2/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit
import QRCoder

extension WalletTableViewController {
    
    internal func showPhotoLibrary() {
        if DataStore.shared.cameraAccess {
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.delegate = self
            
            present(imagePickerController, animated: true, completion: nil)
        } else {
            showConfirmation(title: "wallet.cameraAccess.title".localized,
                             message: "wallet.cameraAccess.message".localized,
                             actions: [("button.title.dontallow".localized, IBMAlertActionStyle.cancel), ("button.title.ok".localized, IBMAlertActionStyle.default)]) { index in
                if index == 1 {
                    DataStore.shared.cameraAccess = true
                    self.showPhotoLibrary()
                }
            }
            
        }
    }

}

extension WalletTableViewController: UIImagePickerControllerDelegate {
    
    // ======================================================================
    // === UIImagePickerController ==================================
    // ======================================================================
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        picker.dismiss(animated: true, completion: {
            self.showScanComplete(with: image)
        })
    }
    
}
