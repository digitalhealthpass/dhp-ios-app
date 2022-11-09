//
//  CustomTabbarController+Deeplink.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit


#if HOLDER

extension CustomTabbarController {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Deeplink Handler Methods
    
    internal func handleDeeplink() {
        guard let deepLinkActionString = DataStore.shared.deepLinkAction, let deepLinkAction = DeeplinkAction(rawValue: deepLinkActionString) else {
            DataStore.shared.resetDeepLinking()
            return
        }
        
        let deepLinkQueries = DataStore.shared.deepLinkQueries
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            if deepLinkAction == .generateKey, SettingsBundleHelper.shared.savedEnvironment.canShowRegistration {
                self.prepareKeyGenDeeplink(deepLinkQueries: deepLinkQueries)
            } else if deepLinkAction == .registration, SettingsBundleHelper.shared.savedEnvironment.canShowRegistration {
                self.prepareConnectionRegistrationDeeplink(deepLinkQueries: deepLinkQueries)
            } else if deepLinkAction == .download, SettingsBundleHelper.shared.savedEnvironment.canShowRegistration {
                self.prepareContactCredentialDownloadDeeplink(deepLinkQueries: deepLinkQueries)
            } else if deepLinkAction == .credential {
                self.prepareCredentialDeeplink(deepLinkQueries: deepLinkQueries)
            }
            
            DataStore.shared.resetDeepLinking()
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Key Generation Method
    
    private func prepareKeyGenDeeplink(deepLinkQueries: [String: String]?) {
        if let navigationController = Storyboard.KeyPairManagement.instantiateViewController(withIdentifier: ControllerIdentifier.Navigation.KeyPairManagement) as? CustomNavigationController,
           let keyPairManagementDetailsTableViewController = navigationController.viewControllers.first as? KeyPairManagementDetailsTableViewController {
            navigationController.modalPresentationStyle = .formSheet
            navigationController.isModalInPresentation = true
            
            let keyTag = deepLinkQueries?[DeeplinkParameters.accessCode.rawValue]
            
            keyPairManagementDetailsTableViewController.keyTag = keyTag
            keyPairManagementDetailsTableViewController.keyPair = nil
            
            present(navigationController, animated: true)
        }
    }
        
    // MARK: - Connection Registration (HIT/BTS) Method
    
    private func prepareConnectionRegistrationDeeplink(deepLinkQueries: [String: String]?) {
        let org = deepLinkQueries?[DeeplinkParameters.org.rawValue]
        let code = deepLinkQueries?[DeeplinkParameters.code.rawValue]
        
        if let navigationController = Storyboard.OrganizationRegistration.instantiateViewController(identifier: ControllerIdentifier.Navigation.OrgRegistration) as? UINavigationController,
           let orgViewController = navigationController.viewControllers.first as? OrgRegistrationViewController {
            orgViewController.modalPresentationStyle = .fullScreen
            orgViewController.isModalInPresentation = true
            
            orgViewController.org = org
            orgViewController.registrationCode = code
            
            present(navigationController, animated: true)
        }
    }
    
    // MARK: - Download Card Method
    
    private func prepareContactCredentialDownloadDeeplink(deepLinkQueries: [String: String]?) {
        let cred = deepLinkQueries?[DeeplinkParameters.cred.rawValue]
        
        if let navigationController = Storyboard.ContactDetails.instantiateViewController(identifier: ControllerIdentifier.Navigation.ContactCredentialDownload) as? UINavigationController,
           let contactDownloadTableViewController = navigationController.viewControllers.first as? ContactDownloadTableViewController {
            contactDownloadTableViewController.modalPresentationStyle = .fullScreen
            contactDownloadTableViewController.isModalInPresentation = true
            
            contactDownloadTableViewController.cred = cred
            
            present(navigationController, animated: true)
        }
    }
    
    // MARK: - Add Card Method
    
    private func prepareCredentialDeeplink(deepLinkQueries: [String: String]?) {
        guard let data = deepLinkQueries?[DeeplinkParameters.data.rawValue] else { return }
        
        if let navigationController = Storyboard.ScanComplete.instantiateViewController(identifier: ControllerIdentifier.Navigation.ScanComplete) as? UINavigationController,
           let scanCompleteViewController = navigationController.viewControllers.first as? ScanCompleteViewController {
            scanCompleteViewController.modalPresentationStyle = .formSheet
            scanCompleteViewController.isModalInPresentation = true
            
            scanCompleteViewController.credentialString = data
            
            self.present(navigationController, animated: true)
        }
    }
}

#endif
