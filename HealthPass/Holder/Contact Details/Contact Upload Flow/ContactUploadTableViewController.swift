//
//  ContactUploadTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import StoreKit

class ContactUploadTableViewController: UITableViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        let profileCredentialSubject = contact?.profileCredential?.extendedCredentialSubject
        if contact?.contactInfoType == .pobox {
            title = profileCredentialSubject?.consentInfo?.piiControllers?.first?.piiController
        } else {
            title = profileCredentialSubject?.rawDictionary?["name"] as? String
        }
        
        uploadDocument()
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var closeBarButtonItem: UIBarButtonItem!
    
    // MARK: - IBAction
    
    @IBAction func onClose(_ sender: Any) {
        generateImpactFeedback()
        
        self.performSegue(withIdentifier: self.unwindToContactDetailsSegue, sender: nil)
        self.performSegue(withIdentifier: self.unwindToCredentialDetailsSegue, sender: nil)
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var contact: Contact?
    
    var uploadedPackages: [Package]?
    
    var selectedPackages = [Package]()
    
    var baseUrl: String?
    var linkId = String()
    var password = String()
    var name = String()
    
    var encryptedCredentialString = String()
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let unwindToContactDetailsSegue = "unwindToContactDetails"
    private let unwindToCredentialDetailsSegue = "unwindToCredentialDetails"
    
    private var processedMetadata = [[String: Any]]()
    private var notProcessedMetadata = [[String: Any]]()
    
    private var messageTitle: String?
    private var messageSubtitle: String?
    private var hidden: Bool = false
    private var success: Bool?
    private var error: Error?

    private var tintColor: UIColor?
    private var statusImage: UIImage?
    
    // MARK: Private Methods
    
    private func requestReview() {
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

    private func uploadDocument() {
        
        showView(with: "contact.credentials.uploading".localized, subtitle: "contact.pleaseWait".localized, hidden: false)
        
        self.closeBarButtonItem.isEnabled = false
        PostboxService().uploadDocuments(at: baseUrl, for: encryptedCredentialString, link: linkId, password: password, name: name) { result in
            self.closeBarButtonItem.isEnabled = true
            
            switch result {
            case .success(let json):
                print(" [RESPONSE] - Upload Document : \(json)")
                guard let payload = json["payload"] as? [String: Any], let _ = payload["id"] as? String else {
                    self.showView(hidden: true, success: false)
                    return
                }
                
                self.submitData(payload: payload)
                
            case .failure(let error):
                print(" [FAIL] - Upload Document - Server response failed : \(error.localizedDescription)")
                self.showView(hidden: true, success: false, error: error)
            }
        }
    }
    
    private func submitData(payload: [String: Any]) {
        showView(with: "contact.credentials.submitting".localized, subtitle: "contact.pleaseWait".localized, hidden: false)
        
        let documentId = payload["id"] as? String ?? String()
        let organization = (contact?.profilePackage?.credential?.extendedCredentialSubject?.rawDictionary?["orgId"] as? String) ?? String("nih") //Fallback to nih if the orgID is not available
        
        let publicKey = contact?.associatedKey?.publickey
        
        let created_at = payload["created_at"] as? String ?? String()
        let expires_at = payload["expires_at"] as? String ?? String()
        let id = payload["id"] as? String ?? String()
        let link = payload["link"] as? String ?? String()
        let name = payload["name"] as? String ?? String()
        
        self.closeBarButtonItem.isEnabled = false
        DataSubmissionService().submitData(at: organization, publicKey: publicKey, documentId: documentId, linkId: linkId) { result in
            self.closeBarButtonItem.isEnabled = true
            
            switch result {
            case .success(let json):
                print(" [RESPONSE] - Submit Data : \(json)")
                
                guard let payload = json["payload"] as? [String : Any], !(payload.isEmpty) else {
                    self.showView(hidden: true, success: false)
                    return
                }
                
                self.processUploadResponse(payload: payload, created_at: created_at, expires_at: expires_at, id: id, link: link, name: name)
                
            case .failure(let error):
                print(" [FAIL] - Submit Data - Server response failed : \(error.localizedDescription)")
                self.showView(hidden: true, success: false, error: error)
            }
        }
        
    }
    
    private func processUploadResponse( payload: [String : Any],
                                        created_at: String,
                                        expires_at: String,
                                        id: String,
                                        link: String,
                                        name: String ) {
        
        // Get the processed and not processed credentials metadata
        // Remove the id credentials since we dont need to store it in DB
        if let credentialsProcessed = payload["credentialsProcessed"] as? [[String: Any]] {
            processedMetadata = credentialsProcessed.filter { ($0["credentialType"] as? String) != "id" }
        }
           
        if let credentialsNotProcessed = payload["credentialsNotProcessed"] as? [[String: Any]] {
            notProcessedMetadata = credentialsNotProcessed.filter { ($0["credentialType"] as? String) != "id" }
        }
        
        //If the filtered list from the already shared list is empty, then none were shared
        if processedMetadata.isEmpty {
            self.showView(hidden: true, success: false)
            return
        }

        //Map and extract only the id from the metadata
        var credentialIdsProcessed: [String] = processedMetadata.compactMap {
            guard let credentialId = $0["credentialId"] else {
                return nil
            }
            
            return String(describing: credentialId)
        }

        if let uploadedPackages = self.uploadedPackages {
            // From the already shared credential list, remove if there is any duplicate and prepare to store in DB
            credentialIdsProcessed = credentialIdsProcessed.filter {
                !( uploadedPackages.compactMap { $0.verifiableObject?.uploadIdentifier }.contains($0) )
            }
         
            //Append the processed credentials with the already shared credential list to prepare for overwriting
            let existingCredentials = uploadedPackages.compactMap({ $0.verifiableObject?.uploadIdentifier })
            credentialIdsProcessed.append(contentsOf: existingCredentials)
        }
                
        
        //Construct the ContactUploadDetails object
        var uploadDetailsData = [String: Any]()
        uploadDetailsData["associatedCredentials"] = credentialIdsProcessed
        uploadDetailsData["contactID"] = self.contact?.idCredential?.id
        
        uploadDetailsData["created_at"] = created_at
        uploadDetailsData["expires_at"] = expires_at
        uploadDetailsData["id"] = id
        uploadDetailsData["link"] = link
        uploadDetailsData["name"] = name
        
        let contactUploadDetails = ContactUploadDetails(value: uploadDetailsData)
        
        //If there are elements in the not processed section, show partially submitted warning
        //Else, show the data successfully submitted message
        if !(notProcessedMetadata.isEmpty) {
            self.tintColor = UIColor.systemYellow
            self.statusImage = UIImage(systemName: "exclamationmark.circle.fill")
        
            self.showView(with: "contact.partiallySubmitted.title".localized, subtitle: "contact.partiallySubmitted.subtitle".localized, hidden: true, success: true)
        } else {
            self.showView(with: "contact.uploadComplete.title".localized, subtitle: "contact.uploadComplete.subtitle".localized, hidden: true, success: true)
            self.requestReview()
        }
        
        //Finally, Save the ContactUploadDetails
        DataStore.shared.saveContactUploadDetails(contactUploadDetails) { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.generateNotificationFeedback(.success)
                DataStore.shared.loadUserData()
            }
        }
        
    }
    
    private func showView(with title: String? = "contact.uploadFailed.title".localized,
                          subtitle: String? = "contact.uploadFailed.subtitle".localized,
                          hidden: Bool, success: Bool? = nil,
                          error: Error? = nil) {
        self.messageTitle =  title
        self.messageSubtitle =  subtitle
        self.hidden = hidden
        self.success = success
        self.error = error
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
    
}

extension ContactUploadTableViewController {
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 1
        if !processedMetadata.isEmpty {
            numberOfSections += 1
        }
        if !notProcessedMetadata.isEmpty {
            numberOfSections += 1
        }
        return numberOfSections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return (!processedMetadata.isEmpty) ? processedMetadata.count : notProcessedMetadata.count
        } else if section == 2 {
            return notProcessedMetadata.count
        }
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return CGFloat(22.0)
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return (!processedMetadata.isEmpty) ? "contact.credentials.credshared".localized : "contact.credentials.notProcessed".localized
        } else if section == 2 {
            return "contact.credentials.notProcessed".localized
        }
        
        return nil
    }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat(22.0)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return CGFloat(360.0)
        } 
        
        return CGFloat(80.0)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "contactUploadStatusCellId", for: indexPath)
            
            let contactImageView = cell.viewWithTag(1) as? UIImageView
            contactImageView?.isHidden = true
            contactImageView?.image = nil
            
            let contactTitleLabel = cell.viewWithTag(2) as? UILabel
            contactTitleLabel?.text = messageTitle
            contactTitleLabel?.adjustsFontSizeToFitWidth = true
            
            var messageSubtitle = messageSubtitle ?? String()
            if let err = error as NSError? {
                let domain = err.domain.isEmpty ? "Domain=Unknown" : "Domain=\(err.domain)"
                let code = "Code=\(err.code)"
                
                messageSubtitle = messageSubtitle + String("\n\n(\(domain) | \(code))")
            }

            let contactSubTitleLabel = cell.viewWithTag(3) as? UILabel
            contactSubTitleLabel?.text = messageSubtitle
            contactSubTitleLabel?.adjustsFontSizeToFitWidth = true
            
            let contactActivityIndicatorView = cell.viewWithTag(4) as? UIActivityIndicatorView
            contactActivityIndicatorView?.isHidden = hidden
            
            if let success = success {
                contactTitleLabel?.textColor =  success ? UIColor.systemGreen : UIColor.systemRed
                contactTitleLabel?.adjustsFontSizeToFitWidth = true
                contactImageView?.tintColor =  success ? UIColor.systemGreen : UIColor.systemRed
                
                contactImageView?.isHidden = false
                contactImageView?.image = success ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "xmark.circle.fill")
            }
            
            if let tintColor = tintColor {
                contactTitleLabel?.textColor = tintColor
                contactImageView?.tintColor = tintColor
            }
            if let statusImage = statusImage {
                contactImageView?.image = statusImage
            }
            
            cell.selectionStyle = .none
            cell.isUserInteractionEnabled = false
            
            return cell
        } else if indexPath.section == 1 {
            let credentialMetadata = (!processedMetadata.isEmpty) ? processedMetadata[indexPath.row] : notProcessedMetadata[indexPath.row]
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "contactUploadCredentialCell", for: indexPath) as? ContactCredentialTableViewCell else {
                return UITableViewCell()
            }

            let errorMessage = credentialMetadata["reason"] as? String
            if let credentialId = credentialMetadata["credentialId"] as? String,
               let package = DataStore.shared.getPackage(for: credentialId) ?? DataStore.shared.getDCCPackage(for: credentialId) {
                cell.populateCell(with: package, isSelected: false, enabled: false, errorMessage: errorMessage)
            } else if let nbf = credentialMetadata["credentialId"] as? UInt64,
                      let package = DataStore.shared.getPackage(for: nbf) {
                cell.populateCell(with: package, isSelected: false, enabled: false, errorMessage: errorMessage)
            } else {
                cell.defaultCell()
            }
            
            if let _ = credentialMetadata["reason"] as? String {
                cell.selectionStyle = .default
                cell.tintColor = .systemRed
                cell.accessoryType = .detailButton
                cell.isUserInteractionEnabled = true
            } else {
                cell.selectionStyle = .none
                cell.tintColor = .systemBlue
                cell.accessoryType = .none
                cell.isUserInteractionEnabled = false
            }


            return cell
        } else if indexPath.section == 2 {
            let credentialMetadata = notProcessedMetadata[indexPath.row]
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "contactUploadCredentialCell", for: indexPath) as? ContactCredentialTableViewCell else {
                return UITableViewCell()
            }
            
            if let credentialId = credentialMetadata["credentialId"] as? String,
                let package = DataStore.shared.getPackage(for: credentialId) ?? DataStore.shared.getDCCPackage(for: credentialId) {
                cell.populateCell(with: package, isSelected: false, enabled: false)
            } else if let nbf = credentialMetadata["credentialId"] as? UInt64,
                        let package = DataStore.shared.getPackage(for: nbf) {
                cell.populateCell(with: package, isSelected: false, enabled: false)
            } else {
                cell.defaultCell()
            }
            
            if let _ = credentialMetadata["reason"] as? String {
                cell.selectionStyle = .default
                cell.tintColor = .systemRed
                cell.accessoryType = .detailButton
                cell.isUserInteractionEnabled = true
            } else {
                cell.selectionStyle = .none
                cell.tintColor = .systemBlue
                cell.accessoryType = .none
                cell.isUserInteractionEnabled = false
            }

            return cell
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var errorReason: String?
        
        if indexPath.section == 1   {
            let credentialMetadata = (!processedMetadata.isEmpty) ? processedMetadata[indexPath.row] : notProcessedMetadata[indexPath.row]
            errorReason = credentialMetadata["reason"] as? String
        } else if indexPath.section == 2 {
            let credentialMetadata = notProcessedMetadata[indexPath.row]
            errorReason = credentialMetadata["reason"] as? String
        }
        
        if let message = errorReason {
            self.showConfirmation(title: "Upload Error Reason", message: message, actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        var errorReason: String?
        
        if indexPath.section == 1   {
            let credentialMetadata = (!processedMetadata.isEmpty) ? processedMetadata[indexPath.row] : notProcessedMetadata[indexPath.row]
            errorReason = credentialMetadata["reason"] as? String
        } else if indexPath.section == 2 {
            let credentialMetadata = notProcessedMetadata[indexPath.row]
            errorReason = credentialMetadata["reason"] as? String
        }
        
        if let message = errorReason {
            self.showConfirmation(title: "Upload Error Reason", message: message, actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
        }
    }
}
