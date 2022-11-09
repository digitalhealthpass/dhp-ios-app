//
//  ContactDownloadTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import Alamofire

protocol ContactDownloadTableViewControllerDelegate: AnyObject {
    func didFinishVerification(for credential: Credential?, with package: Package?)
    func didFailVerification(for credential: Credential?, with error: Error)
}

class ContactDownloadTableViewController: UITableViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        addToWalletBarButtonItem = UIBarButtonItem(title: "scan.add".localized, style: .done, target: self, action: #selector(addToWallet))
        addToWalletBarButtonItem?.isEnabled = false
        
        let profileCredentialSubject = contact?.profileCredential?.extendedCredentialSubject
        if contact?.contactInfoType == .pobox {
            title = profileCredentialSubject?.consentInfo?.piiControllers?.first?.piiController
        } else {
            title = profileCredentialSubject?.rawDictionary?["name"] as? String
        }

        downloadCredentials()
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    
    // MARK: - IBAction
    
    @IBAction func onCancel(_ sender: Any) {
        generateImpactFeedback()
        
        downloadRequest?.cancel()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var cred: String? {
        didSet {
            contact = DataStore.shared.getContact(for: cred)
        }
    }

    var contact: Contact? {
        didSet {
            title = contact?.profileCredential?.extendedCredentialSubject?.rawDictionary?["name"] as? String
            downloadCredentials()
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private var downloadRequest: DataRequest?
    
    private let unwindToWallet = "unwindToWallet"

    private var messageTitle: String? = "contact.prepareForDownload".localized
    private var messageSubtitle: String? = "contact.wait".localized
    private var isLoading = true
    private var success: Bool?
    
    private var addToWalletBarButtonItem: UIBarButtonItem?
    
    private var decryptedCredentials = [Credential]()
    private var packageDictionary = [String: Package]()
    private var errorDictionary = [String: Error]()
    
    // MARK: Private Methods
    
    @objc
    private func addToWallet() {
        let packages = Array(packageDictionary.values)
        
        self.updateView(with: "contact.addToWallet".localized, subtitle: "contact.wait".localized, isLoading: true, success: nil)

        DataStore.shared.savePackages(packages) { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.updateContact()
            }
        }
    }
    
    private func updateContact() {
        guard var contactJSON = self.contact?.rawDictionary else {
            self.dismissToWallet()
            return
        }
        
        let downloadedCredentialIDs = self.decryptedCredentials.compactMap( { $0.id } )
        var existingDownloadedCredentialIDs = contactJSON["downloadedCredentialIDs"] as? [String] ?? [String]()
        existingDownloadedCredentialIDs.append(contentsOf: downloadedCredentialIDs)
        contactJSON["downloadedCredentialIDs"] = Array(Set(existingDownloadedCredentialIDs))
        
        let updatingContact = Contact(value: contactJSON)
        
        DataStore.shared.updateContact(updatingContact) { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.dismissToWallet()
            }
        }
    }
    
    private func dismissToWallet() {
        self.generateNotificationFeedback(.success)
        DataStore.shared.loadUserData()
        self.performSegue(withIdentifier: self.unwindToWallet, sender: nil)
    }
    
    private func downloadCredentials() {
        guard let contact = self.contact else {
            return
        }
        
        let download = contact.profileCredential?.extendedCredentialSubject?.technical?.download
        let urlString = download?.url
        let linkId = download?.linkId ?? String()
        let passcode = download?.passcode ?? String()
        
        downloadRequest?.cancel()
        
        self.updateView(with: "contact.prepareForDownload".localized, subtitle: "contact.wait".localized, isLoading: true, success: nil)
        downloadRequest = PostboxService().downloadDocuments(urlString: urlString, linkId: linkId, passcode: passcode, completion: { result in
            switch result {
            case .success(let json):
                print(" [RESPONSE] - Download Data : \(json)")
                guard let payload = json["payload"] as? [String : Any], !(payload.isEmpty),
                      let attachments = payload["attachments"] as? [[String: Any]], !(attachments.isEmpty) else {
                    self.updateView(with: "contact.downloadComplete.title".localized, subtitle: "contact.downloadComplete.subtitle".localized, isLoading: false, success: nil)
                    return
                }
                
                self.processDownloadResponse(attachments: attachments)
                
            case .failure(let error):
                print(" [FAIL] - Download Data - Server response failed : \(error.localizedDescription)")
                self.updateView(with: "contact.downloadFailed".localized, subtitle: error.localizedDescription, isLoading: false, success: false)
            }
        })
    }
    
    private func processDownloadResponse(attachments: [[String: Any]]) {
        guard let encryptedCredentials = attachments.compactMap({ $0["content"] }) as? [String] else {
            self.updateView(with: "contact.downloadComplete.title".localized, subtitle: "contact.downloadComplete.subtitle".localized, isLoading: false, success: false)
            return
        }

        decryptedCredentials = encryptedCredentials.compactMap { getDecryptedCredential(for: $0) }
        
        let userPackages = DataStore.shared.userPackages
        let userCredentials = userPackages.compactMap({ $0.credential })
        
        userCredentials.forEach { credential in
            decryptedCredentials = decryptedCredentials.filter { $0.id != credential.id }
        }
        
        decryptedCredentials.forEach { credential in
            let _ = ContactDownloadUtil(delegate: self, constructedCredential: credential)
        }
        
        let subtitle = decryptedCredentials.isEmpty ? "contact.credential.empty".localized : String(format: "contact.credential.format".localized, "\(decryptedCredentials.count)", decryptedCredentials.count > 1 ? "s" : "", decryptedCredentials.count > 1 ? "es" : "")
        let success = decryptedCredentials.isEmpty ? nil : true
        
        self.updateView(with: "contact.downloadComplete.title".localized, subtitle: subtitle, isLoading: false, success: success)
    }
    
    private func updateView(with title: String?, subtitle: String?, isLoading: Bool, success: Bool?) {
        self.messageTitle =  title
        self.messageSubtitle =  subtitle
        self.isLoading = isLoading
        self.success = success

        self.view.isUserInteractionEnabled = !isLoading
        self.cancelBarButtonItem.isEnabled = !isLoading
        self.addToWalletBarButtonItem?.isEnabled = !isLoading

        if let success = success, success {
            navigationItem.rightBarButtonItem = addToWalletBarButtonItem
        } else {
            navigationItem.rightBarButtonItem = nil
        }
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
    
    private func checkAddToWallet() {
        let credentialCount = decryptedCredentials.count
        let packageCount = packageDictionary.count
        let errorCount = errorDictionary.count
        
        addToWalletBarButtonItem?.isEnabled = ((packageCount + errorCount) == credentialCount)
    }
}

extension ContactDownloadTableViewController {
    
    private func getDecryptedCredentialData(for string: String) -> Data? {
        guard let decodedCredentialData = string.base64DecodedData() else {
            return nil
        }
        
        let symmetricKey = contact?.profileCredential?.extendedCredentialSubject?.technical?.symmetricKey
        
        guard let decodedIVData = symmetricKey?.iv?.base64DecodedData() else {
            return nil
        }
        
        guard let decodedKeyData = symmetricKey?.value?.base64DecodedData() else {
            return nil
        }
        
        guard let decryptedData = try? AESCrypto().decrypt(data: decodedCredentialData, key: decodedKeyData, iv: decodedIVData) else {
            return nil
        }
        
        return decryptedData
    }
    
    private func getDecryptedCredentialString(for string: String) -> String? {
        guard let decryptedCredentialsData = getDecryptedCredentialData(for: string) else {
            return nil
        }
        
        return String(data: decryptedCredentialsData, encoding: .utf8)
    }
    
    private func getDecryptedCredentialFile(for string: String) -> [String: Any]? {
        guard let decryptedCredentialsString = getDecryptedCredentialString(for: string) else {
            return nil
        }
        
        guard let data = decryptedCredentialsString.data(using: .utf8) else {
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        
        return json
    }
    
    private func getDecryptedCredential(for string: String) -> Credential? {
        guard let decryptedCredentialsJSON = getDecryptedCredentialFile(for: string) else {
            return nil
        }
        
        return Credential(value: decryptedCredentialsJSON)
    }
    
}

extension ContactDownloadTableViewController {
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let success = success, success else {
            return 1
        }
        
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1, let success = success, success {
            return decryptedCredentials.count
        }
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "contactDownloadStatusCellId", for: indexPath)
            
            let contactTitleLabel = cell.viewWithTag(2) as? UILabel
            contactTitleLabel?.text = messageTitle
            contactTitleLabel?.font = AppFont.title1Scaled

            let contactSubTitleLabel = cell.viewWithTag(3) as? UILabel
            contactSubTitleLabel?.text = messageSubtitle
            contactSubTitleLabel?.font = AppFont.title3Scaled
            
            let contactActivityIndicatorView = cell.viewWithTag(4) as? UIActivityIndicatorView
            contactActivityIndicatorView?.isHidden = !isLoading
            
            if let success = success {
                contactTitleLabel?.textColor = success ? .systemGreen : .systemRed
            } else {
                contactTitleLabel?.textColor = .label
            }
            
            return cell
        } else if indexPath.section == 1,
                  let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCredentialCell", for: indexPath) as? ContactCredentialTableViewCell {
            
            let credential = decryptedCredentials[indexPath.row]
            
            if let id = credential.id, let package = packageDictionary[id] {
                cell.populateCell(with: package, isSelected: false)
                cell.accessoryType = .none
                cell.isUserInteractionEnabled = false
            } else {
                cell.populateCell(with: credential)
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
}

extension ContactDownloadTableViewController: ContactDownloadTableViewControllerDelegate {
    
    func didFinishVerification(for credential: Credential?, with package: Package?) {
        guard let id = credential?.id, let package = package else { return }
        
        packageDictionary[id] = package
        
        checkAddToWallet()
     
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
    
    func didFailVerification(for credential: Credential?, with error: Error) {
        guard let id = credential?.id else { return }
        
        errorDictionary[id] = error
        
        checkAddToWallet()
      
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
}
