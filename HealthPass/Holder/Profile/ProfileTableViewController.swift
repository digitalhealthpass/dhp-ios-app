//
//  ProfileTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import MobileCoreServices

class ProfileTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    static let RefreshKeychainIdentifier = Notification.Name("RefreshKeychainIdentifier")
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateProfileName()
        
        tableView.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didRefreshKeychain(notification:)),
                                               name: ProfileTableViewController.RefreshKeychainIdentifier,
                                               object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.navigationBar.sizeToFit()
        tableView.reloadData()
    }
    
    @IBAction func unwindToProfile(segue: UIStoryboardSegue) {
        updateProfileName()
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet var createKeychainBackupLabel: UILabel!
    @IBOutlet var importKeychainArchiveLabel: UILabel!
    
    @IBOutlet var keyCountLabel: UILabel!
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var envLabel: UILabel!
    @IBOutlet weak var languageLabel: UILabel!
    
    // MARK: - IBAction
    
    @IBAction func privacyBarButton(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: showPrivacyPolicy, sender: nil)
    }
    
    @IBAction func termsConditionsBarButton(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: showTermsConditions, sender: nil)
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private let unwindToLaunchSegue = "unwindToLaunch"
    
    private let showPrivacyPolicy = "showPrivacyPolicy"
    private let showTermsConditions = "showTermsConditions"
    private let showDataCenter = "showDataCenter"
    private let showPasscode = "showPasscode"
    private let showSecurityKeysSegue = "showSecurityKeys"
    private let showResetSegue = "showReset"
    private let showThirdPartyLicenses = "showThirdPartyLicenses"

    // MARK: Private Methods
    
    private func updateProfileName() {
        versionLabel?.text = String(format: "%@", Bundle.main.appVersionNumber ?? "")
        envLabel?.text = SettingsBundleHelper.shared.savedEnvironment.title
        
        let keyCount = DataStore.shared.userKeyPairs.count
        keyCountLabel.text = (keyCount == 0) ? nil : String(keyCount)
        
        languageLabel?.text = Locale.current.languageCode
    }
    
    private func compressKeychainData() {
        let dictionary = DataStore.shared.getSecureStoreData()
        
        let dateString = Date.stringForDate(date: Date(), dateFormatPattern: .keyGenFormat)
        let tag = String("Wallet_Backup_\(dateString)")
        let fileName = String("\(tag).hpzip")
        
        showPasswordAlert(title: "profile.walletBackup.title".localized,
                          message: String(format: "profile.walletBackup.messageFormat".localized, "\(fileName)"),
                          buttonTitle: "profile.walletBackup.now".localized) { password in
            
            guard !password.isEmpty else {
                self.showConfirmation(title: "profile.walletBackup.failed".localized,
                                      message: "profile.walletBackup.failedMessage".localized,
                                      actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
                return
            }
            
            BufferCompression().compress(for: dictionary, to: tag, with: password, completion: { url, errorMessage in
                
                if let url = url {
                    self.generateNotificationFeedback(.success)
                    
                    self.shareFile(for: url)
                    print("url: \(url)")
                } else if let errorMessage = errorMessage {
                    self.generateNotificationFeedback(.error)
                    
                    print("errorMessage: \(errorMessage)")
                }
                
            })
        }
        
    }
    
    private func importKeychainArchive() {
        let importMenu = UIDocumentPickerViewController(documentTypes: [String(kUTTypeHPZipArchive)], in: .import)
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        
        if let popoverPresentationController = importMenu.popoverPresentationController {
            popoverPresentationController.sourceView = self.view
        }
        
        present(importMenu, animated: true, completion: nil)
    }
    
    private func shareFile(for url: URL) {
        let filesToShare = [url]
        let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
        
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = createKeychainBackupLabel
            popoverController.sourceRect = createKeychainBackupLabel.bounds
            
            popoverController.permittedArrowDirections = [.up]
        }
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @objc
    private func didRefreshKeychain(notification: Notification) {
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
}

extension ProfileTableViewController {
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return String("profile.footer".localized)
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        generateImpactFeedback()
        
        if indexPath.section == 0, indexPath.row == 0 {
            compressKeychainData()
        } else if indexPath.section == 0, indexPath.row == 1 {
            importKeychainArchive()
        } else if indexPath.section == 1, indexPath.row == 0 {
            self.performSegue(withIdentifier: showPasscode, sender: nil)
        } else if indexPath.section == 1, indexPath.row == 1 {
            self.performSegue(withIdentifier: showSecurityKeysSegue, sender: nil)
        } else if indexPath.section == 2 {
            self.performSegue(withIdentifier: showResetSegue, sender: nil)
        } else if indexPath.section == 3, indexPath.row == 0 {
            performSegue(withIdentifier: showTermsConditions, sender: nil)
        } else if indexPath.section == 3, indexPath.row == 1 {
            performSegue(withIdentifier: showPrivacyPolicy, sender: nil)
        } else if indexPath.section == 3, indexPath.row == 2 {
            performSegue(withIdentifier: showThirdPartyLicenses, sender: nil)
        } else if indexPath.section == 4, indexPath.row == 0 {
            performSegue(withIdentifier: showDataCenter, sender: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else { return }
        headerView.textLabel?.textColor = .secondaryLabel
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let footerView = view as? UITableViewHeaderFooterView else { return }
        footerView.textLabel?.textColor = .secondaryLabel
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.font = AppFont.bodyScaled
        cell.detailTextLabel?.font = AppFont.bodyScaled
    }
}

extension ProfileTableViewController : UIDocumentPickerDelegate, UINavigationControllerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print("url = \(url)")
        let fileExtension = url.pathExtension as CFString
        if let uniformTypeIdentifier = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil) {
            let uniformTypeRetainedValue = uniformTypeIdentifier.takeRetainedValue()
            if UTTypeConformsTo(uniformTypeRetainedValue, kUTTypeHPZipArchive) {
                importBackup(from: url)
            }  else {
                //TODO: handle error here
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }
    
    private func importBackup(from url: URL) {
        showPasswordAlert(title: "restore.wallet.title".localized,
                          message: "restore.wallet.message".localized,
                          buttonTitle: "restore.buttonTitle".localized) { password in
            DataStore.shared.importKeychainArchive(url: url, with: password, completion: { result in
                switch result {
                case .success(let didSucceed):
                    if didSucceed {
                        self.showConfirmation(title: "restore.complete.title".localized, message: "restore.complete.message".localized,
                                              actions: [("profile.wallet.open".localized, IBMAlertActionStyle.cancel)], completion: { _ in
                            self.performSegue(withIdentifier: "unwindToWallet", sender: nil)
                        })
                        
                        self.generateNotificationFeedback(.success)
                        DataStore.shared.loadUserData()
                        NotificationCenter.default.post(name: ProfileTableViewController.RefreshKeychainIdentifier, object: nil)
                    } else {
                        self.showConfirmation(title: "restore.failed.title".localized, message: "restore.failed.messageUnknown".localized,
                                              actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
                    }
                    
                case .failure(let error):
                    self.showConfirmation(title: "restore.failed.title".localized, message: String(format: "restore.failed.messageFormat".localized, "\(error.localizedDescription)"),
                                          actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
                }
            })
        }
    }
    
    private func readJSONFromFile(fileUrl: URL) -> [String: Any]? {
        do {
            let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
            return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch {
            return nil
        }
    }
    
    private func readJSONFromFile(fileName: String) -> [String: Any]? {
        let components = fileName.components(separatedBy: ".")
        let resource = components.first ?? fileName
        let type = components.last ?? String("json")
        
        if let path = Bundle.main.path(forResource: resource, ofType: type) {
            do {
                let fileUrl = URL(fileURLWithPath: path)
                let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
                return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            } catch {
                return nil
            }
        }
        
        return nil
    }
}
