//
//  SceneDelegate+Deeplink.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit

extension SceneDelegate {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================

    // MARK: - Deeplink Handler Methods
    
    internal func handleDeeplink(url: URL) {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }
        
        DataStore.shared.deepLinkAction = String(urlComponents.path.dropFirst())
        DataStore.shared.deepLinkQueries = parseDeeplinkComponents(urlComponents: urlComponents)
        
        guard DataStore.shared.didLoadHomeController else { return }
        
        guard let viewController = getTopViewController() else { return }
        
        guard let deepLinkActionString = DataStore.shared.deepLinkAction, let deepLinkAction = DeeplinkAction(rawValue: deepLinkActionString) else { return }
        
        let deepLinkQueries = DataStore.shared.deepLinkQueries
        
        if deepLinkAction == .generateKey, SettingsBundleHelper.shared.savedEnvironment.canShowRegistration {
            prepareKeyGenDeeplink(viewController, deepLinkQueries: deepLinkQueries)
        } else if deepLinkAction == .registration, SettingsBundleHelper.shared.savedEnvironment.canShowRegistration {
            prepareConnectionRegistrationDeeplink(viewController, deepLinkQueries: deepLinkQueries)
        } else if deepLinkAction == .download, SettingsBundleHelper.shared.savedEnvironment.canShowRegistration {
            prepareContactCredentialDownloadDeeplink(viewController, deepLinkQueries: deepLinkQueries)
        } else if deepLinkAction == .credential {
            prepareCredentialDeeplink(viewController, deepLinkQueries: deepLinkQueries)
        }
        
        DataStore.shared.resetDeepLinking()
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================

    // MARK: - Deeplink Parser Methods
    
    private func parseDeeplinkComponents(urlComponents: URLComponents) -> [String: String] {
        var qDictionary = [String: String]()
        
        guard let queryItems = urlComponents.queryItems else {
            return qDictionary
        }
        
        for item in queryItems {
            qDictionary[item.name] = item.value
        }
        
        return qDictionary
    }
    
    // MARK: - Key Generation Method

    private func prepareKeyGenDeeplink(_ viewController: UIViewController, deepLinkQueries: [String: String]?) {
        let keyTag = deepLinkQueries?[DeeplinkParameters.accessCode.rawValue]
        
        if let navigationController = Storyboard.KeyPairManagement.instantiateViewController(withIdentifier: ControllerIdentifier.Navigation.KeyPairManagement) as? CustomNavigationController,
           let keyPairManagementDetailsTableViewController = navigationController.viewControllers.first as? KeyPairManagementDetailsTableViewController {
            navigationController.modalPresentationStyle = .formSheet
            navigationController.isModalInPresentation = true
            
            viewController.present(navigationController, animated: true, completion: {
                keyPairManagementDetailsTableViewController.keyTag = keyTag
                keyPairManagementDetailsTableViewController.keyPair = nil
            })
        }
    }
    
    // MARK: - Connection Registration (HIT/BTS) Method

    private func prepareConnectionRegistrationDeeplink(_ viewController: UIViewController, deepLinkQueries: [String: String]?) {
        let org = deepLinkQueries?[DeeplinkParameters.org.rawValue]
        let code = deepLinkQueries?[DeeplinkParameters.code.rawValue]
        
        if let navigationController = Storyboard.OrganizationRegistration.instantiateViewController(identifier: ControllerIdentifier.Navigation.OrgRegistration) as? UINavigationController,
           let orgViewController = navigationController.viewControllers.first as? OrgRegistrationViewController {
            orgViewController.modalPresentationStyle = .fullScreen
            orgViewController.isModalInPresentation = true
            
            orgViewController.org = org
            orgViewController.registrationCode = code
            
            viewController.present(navigationController, animated: true)
        }
    }
    
    // MARK: - Download Card Method

    private func prepareContactCredentialDownloadDeeplink(_ viewController: UIViewController, deepLinkQueries: [String: String]?) {
        let cred = deepLinkQueries?[DeeplinkParameters.cred.rawValue]
        
        if let navigationController = Storyboard.ContactDetails.instantiateViewController(identifier: ControllerIdentifier.Navigation.ContactCredentialDownload) as? UINavigationController,
           let contactDownloadTableViewController = navigationController.viewControllers.first as? ContactDownloadTableViewController {
            contactDownloadTableViewController.modalPresentationStyle = .fullScreen
            contactDownloadTableViewController.isModalInPresentation = true
            
            contactDownloadTableViewController.cred = cred
            
            viewController.present(navigationController, animated: true)
        }
    }
    
    // MARK: - Add Card Method

    private func prepareCredentialDeeplink(_ viewController: UIViewController, deepLinkQueries: [String: String]?) {
        guard let data = deepLinkQueries?[DeeplinkParameters.data.rawValue] else { return }
        
        if let navigationController = Storyboard.ScanComplete.instantiateViewController(identifier: ControllerIdentifier.Navigation.ScanComplete) as? UINavigationController,
           let scanCompleteViewController = navigationController.viewControllers.first as? ScanCompleteViewController {
            scanCompleteViewController.modalPresentationStyle = .pageSheet
            scanCompleteViewController.isModalInPresentation = true
            
            scanCompleteViewController.credentialString = data
            
            viewController.present(navigationController, animated: true)
        }
    }
    
}
