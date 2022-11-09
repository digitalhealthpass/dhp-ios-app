//
//  SceneDelegate+Import.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit
import MobileCoreServices
import QRCoder

extension SceneDelegate {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Keychain Import Methods
    
    internal func prepareKeychainArchiveImport(for url: URL) {
        guard let controller = getTopViewController() else { return }
        
        guard DataStore.shared.didLoadHomeController else { return }
        
        let fileName = url.lastPathComponent
        
        controller.showConfirmation(title: "restore.backup.title".localized,
                                    message: String(format: "restore.backup.messageFormat".localized, "\(fileName)"),
                                    actions: [("Cancel", IBMAlertActionStyle.cancel), ("restore.buttonTitle".localized, IBMAlertActionStyle.default)]) { index in
            if index == 1 {
                controller.showPasswordAlert(title: "restore.wallet.title".localized,
                                             message: String(format: "restore.wallet.messageFormat".localized, "\(fileName)"),
                                             buttonTitle: "restore.buttonTitle".localized) { password in
                    DataStore.shared.importKeychainArchive(url: url, with: password, completion: { result in
                        switch result {
                        case .success(let didSucceed):
                            if didSucceed {
                                controller.showConfirmation(title: "restore.complete.title".localized,
                                                            message: "restore.complete.message".localized,
                                                            actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
                                
                                controller.generateNotificationFeedback(.success)
                                DataStore.shared.loadUserData()
                                NotificationCenter.default.post(name: ProfileTableViewController.RefreshKeychainIdentifier, object: nil)
                            } else {
                                controller.showConfirmation(title: "restore.failed.title".localized,
                                                            message: "restore.failed.messageUnknown".localized,
                                                            actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
                            }
                            
                        case .failure(let error):
                            controller.showConfirmation(title: "restore.failed.title".localized,
                                                        message: String(format: "restore.failed.messageFormat".localized, "\(error.localizedDescription)"),
                                                        actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
                        }
                    })
                }
            }
        }
    }
    
    // MARK: - Credential Import Methods
    
    internal func prepareCredentialFileImport(for url: URL) {
        guard let topController = getTopViewController() else { return }
        
        guard DataStore.shared.didLoadHomeController else { return }
        
        guard let rawData = FileManager.default.contents(atPath: url.path), let contents = String(data: rawData, encoding: .utf8)?.base64Encoded() else { return }
        
        guard let navigationController = Storyboard.ScanComplete.instantiateViewController(identifier: ControllerIdentifier.Navigation.ScanComplete) as? UINavigationController,
              let scanCompleteViewController = navigationController.viewControllers.first as? ScanCompleteViewController else { return }
        
        scanCompleteViewController.modalPresentationStyle = .pageSheet
        scanCompleteViewController.isModalInPresentation = true
        scanCompleteViewController.credentialString = contents

        topController.present(navigationController, animated: true)
    }
    
    internal func prepareSHCFileImport(for url: URL) {
        guard let topController = getTopViewController() else { return }
        
        guard DataStore.shared.didLoadHomeController else { return }
        
        let _ = url.startAccessingSecurityScopedResource()
        
        guard let rawData = FileManager.default.contents(atPath: url.path), let json = try? JSONSerialization.jsonObject(with: rawData, options: []) as? [String : Any], let values = json["verifiableCredential"] as? [String], let data = values.first?.data(using: .utf8) else { return }
        
        let _ = url.stopAccessingSecurityScopedResource()
        
        guard let navigationController = Storyboard.ScanComplete.instantiateViewController(identifier: ControllerIdentifier.Navigation.ScanComplete) as? UINavigationController,
              let scanCompleteViewController = navigationController.viewControllers.first as? ScanCompleteViewController else { return }
        
        scanCompleteViewController.modalPresentationStyle = .pageSheet
        scanCompleteViewController.isModalInPresentation = true
        scanCompleteViewController.credentialData = data
    
        topController.present(navigationController, animated: true)
    }
    
    
    internal func prepareCardImageImport(for url: URL) {
        guard let topController = getTopViewController() else { return }
        
        guard DataStore.shared.didLoadHomeController else { return }
        
        let fileExtension = url.pathExtension as CFString
        
        guard let uniformTypeIdentifier = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil) else { return }
        
        let uniformTypeRetainedValue = uniformTypeIdentifier.takeRetainedValue()
        
        let _ = url.startAccessingSecurityScopedResource()
        
        guard UTTypeConformsTo(uniformTypeRetainedValue, kUTTypeImage), let data = try? Data(contentsOf: url, options: [.alwaysMapped, .uncached]), let image = UIImage(data: data) else { return }
        
        let _ = url.stopAccessingSecurityScopedResource()
        
        QRCodeDecoder().decode(image: image, completion: { messages, details, error in
            let detailsMessages = details?.compactMap { $0["message"] as? String ?? $0["rawMessage"] as? String }
            guard let messages = messages, let message = messages.first ?? detailsMessages?.first else { return }
            
            guard let navigationController = Storyboard.ScanComplete.instantiateViewController(identifier: ControllerIdentifier.Navigation.ScanComplete) as? UINavigationController,
                  let scanCompleteViewController = navigationController.viewControllers.first as? ScanCompleteViewController else { return }
            
            scanCompleteViewController.modalPresentationStyle = .formSheet
            scanCompleteViewController.isModalInPresentation = true
            scanCompleteViewController.credentialString = message
            
            topController.present(navigationController, animated: true)
        })
        
    }
    
}
