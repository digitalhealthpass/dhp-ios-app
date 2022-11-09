//
//  CustomTabbarController+Import.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import QRCoder
import MobileCoreServices

#if HOLDER

extension CustomTabbarController {
    
    internal func prepareKeychainArchiveImport(for url: URL) {
        let fileName = url.lastPathComponent
        
        showConfirmation(title: "restore.backup.title".localized,
                         message: String(format: "restore.backup.messageFormat".localized, "\(fileName)"),
                         actions: [("button.title.cancel".localized, IBMAlertActionStyle.cancel), ("restore.buttonTitle".localized, IBMAlertActionStyle.default)]) { index in
            if index == 1 {
                self.showPasswordAlert(title: "restore.wallet.title".localized,
                                       message: String(format: "restore.wallet.messageFormat".localized, "\(fileName)"),
                                       buttonTitle: "restore.buttonTitle".localized) { password in
                    DataStore.shared.importKeychainArchive(url: url, with: password, completion: { result in
                        switch result {
                        case .success(let didSucceed):
                            if didSucceed {
                                self.showConfirmation(title: "restore.complete.title".localized,
                                                      message: "restore.complete.message".localized,
                                                      actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
                                
                                self.generateNotificationFeedback(.success)
                                DataStore.shared.loadUserData()
                                NotificationCenter.default.post(name: ProfileTableViewController.RefreshKeychainIdentifier, object: nil)
                            } else {
                                self.showConfirmation(title: "restore.failed.title".localized,
                                                      message: "restore.failed.messageUnknown".localized,
                                                      actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
                            }
                            
                        case .failure(let error):
                            self.showConfirmation(title: "restore.failed.title".localized,
                                                  message: String(format: "restore.failed.messageFormat".localized, "\(error.localizedDescription)"),
                                                  actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
                        }
                    })
                }
            }
        }
        
        DataStore.shared.resetDeepLinking()
    }
    
    // MARK: - Credential Import Methods
    
    internal func prepareCredentialFileImport(for url: URL) {
        guard let rawData = FileManager.default.contents(atPath: url.path), let contents = String(data: rawData, encoding: .utf8)?.base64Encoded() else { return }
        
        guard let navigationController = Storyboard.ScanComplete.instantiateViewController(identifier: ControllerIdentifier.Navigation.ScanComplete) as? UINavigationController,
              let scanCompleteViewController = navigationController.viewControllers.first as? ScanCompleteViewController else { return }
        
        scanCompleteViewController.modalPresentationStyle = .pageSheet
        scanCompleteViewController.isModalInPresentation = true
        scanCompleteViewController.credentialString = contents
        
        self.present(navigationController, animated: true)
    }
    
    internal func prepareSHCFileImport(for url: URL) {
        let _ = url.startAccessingSecurityScopedResource()
        
        guard let rawData = FileManager.default.contents(atPath: url.path), let json = try? JSONSerialization.jsonObject(with: rawData, options: []) as? [String : Any], let values = json["verifiableCredential"] as? [String], let data = values.first?.data(using: .utf8) else { return }
        
        let _ = url.stopAccessingSecurityScopedResource()
        
        guard let navigationController = Storyboard.ScanComplete.instantiateViewController(identifier: ControllerIdentifier.Navigation.ScanComplete) as? UINavigationController,
              let scanCompleteViewController = navigationController.viewControllers.first as? ScanCompleteViewController else { return }
        
        scanCompleteViewController.modalPresentationStyle = .pageSheet
        scanCompleteViewController.isModalInPresentation = true
        scanCompleteViewController.credentialData = data
    
        self.present(navigationController, animated: true)
    }

    internal func prepareCardImageImport(url: URL) {
        let fileExtension = url.pathExtension as CFString
        
        guard let uniformTypeIdentifier = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil) else {
            DataStore.shared.resetDeepLinking()
            return
        }
        
        let uniformTypeRetainedValue = uniformTypeIdentifier.takeRetainedValue()
        
        let _ = url.startAccessingSecurityScopedResource()
        
        guard UTTypeConformsTo(uniformTypeRetainedValue, kUTTypeImage), let data = try? Data(contentsOf: url, options: [.alwaysMapped, .uncached]), let image = UIImage(data: data) else {
            DataStore.shared.resetDeepLinking()
            return
        }
        
        let _ = url.stopAccessingSecurityScopedResource()
        
        QRCodeDecoder().decode(image: image, completion: { messages, details, error in
            let detailsMessages = details?.compactMap { $0["message"] as? String ?? $0["rawMessage"] as? String }
            guard let messages = messages, let message = messages.first ?? detailsMessages?.first else { return }
            
            guard let navigationController = Storyboard.ScanComplete.instantiateViewController(identifier: ControllerIdentifier.Navigation.ScanComplete) as? UINavigationController,
                  let scanCompleteViewController = navigationController.viewControllers.first as? ScanCompleteViewController else { return }
            
            scanCompleteViewController.modalPresentationStyle = .formSheet
            scanCompleteViewController.isModalInPresentation = true
            scanCompleteViewController.credentialString = message
            
            self.present(navigationController, animated: true)
        })
        
        DataStore.shared.resetDeepLinking()
    }
}

#endif
