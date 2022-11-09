//
//  WalletTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import MobileCoreServices
import QRCoder
import HealthKit
import StoreKit

enum OpenOptionsAction: String {
    case none = "none"
    
    case scanQRCode = "scanQRCode"
    case photosQRCode = "photosQRCode"
    
    case importSHCExtension = "importSHCExtension"
    
    case appleHealth = "appleHealth"
}

class WalletTableViewController: UITableViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DataStore.shared.performMigration()
        
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "WalletTableViewHeaderFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "WalletTableViewHeaderFooterView")
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refreshKeychain(notification:)),
                                               name: ProfileTableViewController.RefreshKeychainIdentifier,
                                               object: nil)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.performSegue(withIdentifier: self.replaceSnapshot, sender: nil)
        }
        
        refreshKeychain()
        
        checkExistingConnections()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshKeychain()
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? CustomNavigationController {
            if let credentialDetailsTableViewController = navigationController.viewControllers.first as? CredentialDetailsTableViewController,
               let package = sender as? Package {
                credentialDetailsTableViewController.package = package
            } else if let contactCompleteViewController = navigationController.viewControllers.first as? ContactCompleteViewController,
                      let contactTuple = sender as? (Credential, Credential) {
                contactCompleteViewController.contactTuple = contactTuple
            } else if let scanCompleteViewController = navigationController.viewControllers.first as? ScanCompleteViewController {
                if let credentialData = sender as? Data {
                    scanCompleteViewController.credentialData = credentialData
                } else if let credentialString = sender as? String {
                    scanCompleteViewController.credentialString = credentialString
                }
            } else if let importCompleteViewController = navigationController.viewControllers.first as? ImportCompleteViewController {
                if let credentialData = sender as? [Data] {
                    importCompleteViewController.credentialData = credentialData
                } else if let credentialString = sender as? [String] {
                    importCompleteViewController.credentialString = credentialString
                }
            } else if let contactDetailsTableViewController = navigationController.viewControllers.first as? ContactDetailsTableViewController,
                      let contact = sender as? Contact {
                contactDetailsTableViewController.contact = contact
                contactDetailsTableViewController.uploadFlow = self.uploadFlow
            } else if let orgRegistrationViewController = navigationController.viewControllers.first as? OrgRegistrationViewController,
                      let org = sender as? String {
                orgRegistrationViewController.org = org
            }
        }
    }
    
    @IBAction func unwindToWallet(segue: UIStoryboardSegue) {
        if let openOptionsTableViewController = segue.source as? OpenOptionsTableViewController {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                let openOptionsAction = openOptionsTableViewController.openOptionsAction
                if openOptionsAction == .scanQRCode {
                    self.performSegue(withIdentifier: self.presentScan, sender: nil)
                } else if openOptionsAction == .photosQRCode {
                    self.showPhotoLibrary()
                } else if openOptionsAction == .importSHCExtension {
                    self.showFiles()
                } else if openOptionsAction == .appleHealth {
                    self.showAppleHealth()
                }
            }
        } else if let registrationDetailsViewController = segue.source as? RegistrationDetailsViewController, let contactTuple = registrationDetailsViewController.contactTuple {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.performSegue(withIdentifier: self.presentContactComplete, sender: contactTuple)
            }
        } else if let orgController = segue.source as? OrgRegistrable, let contactTuple = orgController.contactTuple {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.performSegue(withIdentifier: self.presentContactComplete, sender: contactTuple)
            }
        } else if let contactCompleteViewController = segue.source as? ContactCompleteViewController, let contact = contactCompleteViewController.contact {
            self.uploadFlow = contactCompleteViewController.uploadFlow
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.handleNewConnection(contact)
            }
            selectedObject = nil
            refreshKeychain()
        } else if let scanCompleteViewController = segue.source as? ScanCompleteViewController, let package = scanCompleteViewController.package {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.handleNewCredential(package)
            }
            selectedObject = nil
            refreshKeychain()
        } else if let _ = segue.source as? ConnectionListTableViewController {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.showNewRegistration()
            }
            selectedObject = nil
            refreshKeychain()
        } else {
            selectedObject = nil
            refreshKeychain()
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if segue.source is CredentialDetailsTableViewController || segue.source is ContactDetailsTableViewController || segue.source is DeleteConnectionTableViewController {
                self.performSegue(withIdentifier: self.replaceSnapshot, sender: nil)
            }
        }
        
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    let presentAddOptions = "presentAddOptions"
    let presentNewRegistration = "presentNewRegistration"
    
    let presentScanComplete = "presentScanComplete"
    let presentImportComplete = "presentImportComplete"
    
    var credentialDetails: String { return (UIDevice.current.userInterfaceIdiom == .pad) ? replaceCredentialDetails : presentCredentialDetails }
    var contactDetails: String { return (UIDevice.current.userInterfaceIdiom == .pad) ? replaceContactDetails : presentContactDetails }
    
    var isPackageEmpty: Bool { return packageArray.isEmpty }
    var packageArray: [Package] = [] {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    var isContactEmpty: Bool { return contactsArray.isEmpty }
    var contactsArray: [Contact] = [] {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    var selectedObject: Any?
  
    // MARK: Internal Methods

    internal func requestReview() {
        // Get the current bundle version for the app
        let infoDictionaryKey = kCFBundleVersionKey as String
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String else { return }
        
        let lastVersionPromptedForReview = UserDefaults.standard.string(forKey: UserDefaultsKey.kLastVersionPromptedForReview.rawValue)
        
        // The user has not already been prompted for this version?
        if currentVersion != lastVersionPromptedForReview {
            let twoSecondsFromNow = DispatchTime.now() + 2.0
            DispatchQueue.main.asyncAfter(deadline: twoSecondsFromNow) {
                SKStoreReviewController.requestReview()
                UserDefaults.standard.set(currentVersion, forKey: UserDefaultsKey.kLastVersionPromptedForReview.rawValue)
            }
        }
    }

    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let replaceSnapshot = "replaceSnapshot"
    
    private let presentContactComplete = "presentContactComplete"
    
    private let presentCredentialDetails = "presentCredentialDetails"
    private let replaceCredentialDetails = "replaceCredentialDetails"
    
    private let presentContactDetails = "presentContactDetails"
    private let replaceContactDetails = "replaceContactDetails"
    
    private let presentScan = "presentScan"
    
    private var uploadFlow: Bool = false
    
    // MARK: Private Methods
    
    @objc
    private func refreshKeychain(notification: Notification? = nil) {
        DataStore.shared.loadUserData()
        
        packageArray = DataStore.shared.userPackages
        contactsArray = DataStore.shared.userContacts
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
    
    private func handleNewConnection(_ contact: Contact) {
        guard uploadFlow else { return }
        
        performSegue(withIdentifier: self.contactDetails, sender: contact)
        uploadFlow = false
    }
    
}

extension WalletTableViewController {
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Methods
    
    internal func showScanComplete(with image: UIImage?) {
        guard let image = image else {
            //TODO: handle error here
            return
        }
        
        QRCodeDecoder().decode(image: image,
                               completion: { messages, details, error in
            let detailsMessages = details?.compactMap { $0["message"] as? String ?? $0["rawMessage"] as? String }
            if let error = error {
                let title = "wallet.decodeError.title".localized
                let message = error.localizedDescription
                self.showErrorAlert(title: title, message: message)
                return
            } else if let messages = messages, let message = messages.first ?? detailsMessages?.first  {
                self.showScanComplete(with: message)
            }
        })
    }
    
    internal func showScanComplete(with message: String) {
        generateNotificationFeedback(.success)
        
        performSegue(withIdentifier: presentScanComplete, sender: message)
    }
    
    internal func showScanComplete(with data: Data) {
        generateNotificationFeedback(.success)
        
        performSegue(withIdentifier: presentScanComplete, sender: data)
    }
    
    internal func showScanComplete(with jwsRepresentationRecords: [Data]) {
        generateNotificationFeedback(.success)
        
        guard !(jwsRepresentationRecords.isEmpty) else {
            let title = "wallet.HealthKitError.title".localized
            let message = "wallet.HealthKitError.message".localized
            self.showErrorAlert(title: title, message: message)
            return
        }
        
        performSegue(withIdentifier: presentImportComplete, sender: jwsRepresentationRecords)
    }
    
    internal func showErrorAlert(title: String, message: String) {
        generateNotificationFeedback(.error)
        
        showConfirmation(title: title, message: message, actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
    }
}
