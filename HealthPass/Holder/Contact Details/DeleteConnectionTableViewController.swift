//
//  DeleteConnectionTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import os.log
import PromiseKit
import Alamofire

class DeleteConnectionTableViewController: UITableViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateTitle()
        initActivityIndicator()
        
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        offboardRequest?.cancel()
        getConsentRevokeRequest?.cancel()
        uploadDocumentsRequest?.cancel()
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var deleteTableViewCell: UITableViewCell!
    @IBOutlet weak var revokeSwitch: UISwitch!
    
    @IBOutlet weak var activityIndicatorView: UIView?
    
    // MARK: - IBAction
    
    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "unwindToContactDetails", sender: nil)
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var contact: Contact?
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    // FIXME: Need move to the place with constant
    private let proofTypeValue = "CKM_SHA256_RSA_PKCS_PSS"
    
    private var consentRevokePayload = [String: Any]()
    private var uploadDocumentTuple: (id:String, payload: String)?
    
    private var offboardRequest: DataRequest?
    private var getConsentRevokeRequest: DataRequest?
    private var uploadDocumentsRequest: DataRequest?
    
    // MARK: Private Methods
    
    private func updateTitle() {
        if let consentInfo = contact?.profileCredential?.extendedCredentialSubject?.consentInfo {
            let piiController = consentInfo.piiControllers?.first?.piiController ?? String("-")
            navigationItem.title = piiController
        } else if let contact = contact?.profileCredential?.extendedCredentialSubject?.rawDictionary?["name"] as? String {
            navigationItem.title = contact
        }
    }
    
    private func onDelete() {
        self.showConfirmation(title: "contact.delete.title".localized, message: "contact.delete.message".localized,
                              actions: [("cred.delete.title".localized, IBMAlertActionStyle.destructive),
                                        ("button.title.cancel".localized, IBMAlertActionStyle.cancel)],
                              completion: { index in
            if index == 0 {
                self.showActivityIndicator()
                
                if self.revokeSwitch.isOn {
                    self.revokeAndOffBoardFlow()
                } else {
                    self.offBoardFlow()
                }
            }
        })
    }
    
    private func offBoardFlow() {
        self.offBoardContact()
            .done {
                self.hideActivityIndicator()
                self.generateNotificationFeedback(.success)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    DataStore.shared.loadUserData()
                    self.performSegue(withIdentifier: "unwindToWallet", sender: nil)
                }
            }
            .catch { error in
                self.hideActivityIndicator()
                self.generateNotificationFeedback(.error)
                
                self.showConfirmation(title: "contact.offboardingFailed.title".localized, message: "contact.offboardingFailed.message".localized,
                                      actions: [("button.title.cancel".localized , IBMAlertActionStyle.cancel), ("contact.offboardingFailed.button2".localized , IBMAlertActionStyle.destructive)]) { index in
                    if index == 1 {
                        DataStore.shared.deleteContact(self.contact!) { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                                DataStore.shared.loadUserData()
                                self.performSegue(withIdentifier: "unwindToWallet", sender: nil)
                            }
                        }
                    }
                }
            }
            .finally {
                self.consentRevokePayload = [String: Any]()
                self.uploadDocumentTuple = nil
            }
    }
    
    private func revokeAndOffBoardFlow() {
        self.getConsentRevoke()
            .then { _ in
                self.uploadDocument()
            }
            .then { _ in
                self.offBoardContact()
            }
            .done { _ in
                DispatchQueue.main.async {
                    self.hideActivityIndicator()
                    self.generateNotificationFeedback(.success)
                    
                    DataStore.shared.loadUserData()
                    self.performSegue(withIdentifier: "unwindToWallet", sender: nil)
                }
            }
            .catch { error in
                self.hideActivityIndicator()
                self.generateNotificationFeedback(.error)
                
                self.showConfirmation(title: "contact.offboardingFailed.title".localized, message: "contact.offboardingFailed.message".localized,
                                      actions: [("button.title.cancel".localized , IBMAlertActionStyle.cancel), ("contact.offboardingFailed.button2".localized , IBMAlertActionStyle.destructive)]) { index in
                    if index == 1 {
                        DataStore.shared.deleteContact(self.contact!) { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                                DataStore.shared.loadUserData()
                                self.performSegue(withIdentifier: "unwindToWallet", sender: nil)
                            }
                        }
                    }
                }
            }
            .finally {
                self.consentRevokePayload = [String: Any]()
                self.uploadDocumentTuple = nil
            }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            onDelete()
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.font = AppFont.bodyScaled
        cell.detailTextLabel?.font = AppFont.bodyScaled
    }
    
}

// MARK: UI Methods
private extension DeleteConnectionTableViewController {
    
    private func showActivityIndicator() {
        activityIndicatorView?.isHidden = false
    }
    
    private func hideActivityIndicator() {
        activityIndicatorView?.isHidden = true
    }
    
    private func initActivityIndicator() {
        self.view.addSubview(self.activityIndicatorView!)
        self.view.bringSubviewToFront(self.activityIndicatorView!)
        
        self.activityIndicatorView?.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.activityIndicatorView!.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            self.activityIndicatorView!.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        
        hideActivityIndicator()
    }
}

// Off Board flow
extension DeleteConnectionTableViewController {
    
    private func offBoardContact() -> Promise<Void> {
        return Promise(resolver: { resolver in
            guard let contact = contact else {
                let formatError = NSError.invalidDataResponseError
                resolver.reject(formatError)
                return
            }
            
            let orgId = contact.getOrganizationId()
            let contactId = contact.idPackage?.credential?.extendedCredentialSubject?.id ?? String()
            
            let publickey = contact.associatedKey?.publickey ?? ""
            let documentId: String? = uploadDocumentTuple?.id
            
            guard let signedConsentReceipt = self.constructProofSection(for: consentRevokePayload) else {
                let formatError = NSError.invalidDataResponseError
                resolver.reject(formatError)
                return
            }
            
            self.offboardRequest = DataSubmissionService().offBoardContact(for: orgId, contactId: contactId,
                                                                              linkId: getLinkId(),publickey: publickey, documentId: documentId, signedConsentReceipt: signedConsentReceipt) { result in
                switch result {
                case .success:
                    DataStore.shared.deleteContact(contact) { deleteResult in
                        switch deleteResult {
                        case .success:
                            os_log("[Success] - DeleteCard", log: OSLog.contactDetails, type: .info)
                        case .failure:
                            os_log("[FAIL] - DeleteCard from DataStore error", log: OSLog.contactDetails, type: .error)
                        }
                        
                        resolver.fulfill_()
                        return
                    }
                    
                case .failure(let error):
                    resolver.reject(error)
                    return
                }
            }
        })
    }
    
}

// Consent Revoke flow
extension DeleteConnectionTableViewController {
    
    private func getConsentRevoke() -> Promise<Void> {
        return Promise(resolver: { resolver in
            guard let contact = contact else {
                let formatError = NSError.invalidDataResponseError
                resolver.reject(formatError)
                return
            }
            
            let orgId = contact.getOrganizationId()
            let publickey = contact.associatedKey?.publickey ?? ""
            
            self.showActivityIndicator()
            
            self.getConsentRevokeRequest = DataSubmissionService().getConsentRevoke(for: orgId, publickey: publickey) { result in
                switch result {
                case .success(let json):
                    guard let payload = json["payload"] as? [String: Any] else {
                        let formatError = NSError.invalidDataResponseError
                        resolver.reject(formatError)
                        return
                    }
                    
                    self.consentRevokePayload = payload
                    os_log("[Success] - GetConsentRevoke", log: OSLog.contactDetails, type: .info)
                    resolver.fulfill_()
                    return
                    
                case .failure(let error):
                    os_log("[FAIL] - GetConsentRevoke error", log: OSLog.contactDetails, type: .error)
                    resolver.reject(error)
                    return
                }
            }
        })
    }
    
    private func uploadDocument() -> Promise<Void> {
        return Promise(resolver: { resolver in
            guard let contact = contact else {
                let formatError = NSError.invalidDataResponseError
                resolver.reject(formatError)
                return
            }
            
            let linkId = getLinkId()
            
            guard let content = getBase64EncryptedString(payload: consentRevokePayload) else {
                let formatError = NSError.invalidDataResponseError
                resolver.reject(formatError)
                return
            }
            
            let password = contact.profileCredential?.extendedCredentialSubject?.technical?.poBox?.passcode
            ?? contact.profileCredential?.extendedCredentialSubject?.technical?.upload?.passcode
            ?? String()
            
            let piiController = contact.profileCredential?.extendedCredentialSubject?.consentInfo?.piiControllers?.first?.piiController ?? String("Untitled")
            let dateString = Date.stringForDate(date: Date())
            let name = String(format: "%@_%@", piiController, dateString)
            
            self.uploadDocumentsRequest = PostboxService().uploadDocuments(at: nil, for: content, link: linkId, password: password, name: name) { result in
                switch result {
                case .success(let json):
                    os_log("[SUCCESS] - Upload Document", log: OSLog.contactDetails, type: .error)
                    guard let documentPayload = json["payload"] as? [String: Any], let id = documentPayload["id"] as? String else {
                        let formatError = NSError.invalidDataResponseError
                        resolver.reject(formatError)
                        return
                    }
                    
                    self.uploadDocumentTuple = (id: id, payload: content)
                    resolver.fulfill_()
                    return
                    
                case .failure(let error):
                    print(" [FAIL] - Upload Document - Server response failed : \(error.localizedDescription)")
                    resolver.reject(error)
                    return
                }
            }
        })
    }
    
    // Methods for Upload Document
    
    private func getLinkId() -> String {
        return contact?.profileCredential?.extendedCredentialSubject?.technical?.poBox?.linkId
        ?? contact?.profileCredential?.extendedCredentialSubject?.technical?.upload?.linkId
        ?? String()
    }
    
    private func getBase64EncryptedString(payload: [String: Any]) -> String? {
        guard let encryptedData = getEncryptedDataForConsentRevoke(payload: payload) else {
            return nil
        }
        
        let base64EncryptedString = encryptedData.base64EncodedString()
        return base64EncryptedString
    }
    
    private func getEncryptedDataForConsentRevoke(payload: [String: Any]) -> Data? {
        
        let symmetricKey = contact?.profileCredential?.extendedCredentialSubject?.technical?.poBox?.symmetricKey
        ?? contact?.profileCredential?.extendedCredentialSubject?.technical?.symmetricKey
        
        guard let decodedIVData = symmetricKey?.iv?.base64DecodedData() else {
            os_log("IVData decoding error -- ", log: OSLog.dataEncryption, type: .error)
            return nil
        }
        
        guard let decodedKeyData = symmetricKey?.value?.base64DecodedData() else {
            os_log("KeyData decoding error -- ", log: OSLog.dataEncryption, type: .error)
            return nil
        }
        
        // sign concent receipt here for separate logic
        guard let concentReceiptDictionary = constructProofSection(for: payload) else {
            os_log("Proof section constructing error -- ", log: OSLog.dataEncryption, type: .error)
            return nil
        }
        
        guard let payloadJSONData = try? JSONSerialization.data(withJSONObject: concentReceiptDictionary, options: [.sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]) as Data else {
            os_log("Postbox dictionary serialization error -- JSONSerialization data error", log: OSLog.dataEncryption, type: .error)
            return nil
        }
        
        guard let payloadRawString = String(data: payloadJSONData, encoding: .ascii) else {
            os_log("PostboxJSONData encoding error -- ", log: OSLog.dataEncryption, type: .error)
            return nil
        }
        
        guard let payloadData = payloadRawString.data(using: .ascii) else {
            os_log("PostboxRawString converting to data error -- ", log: OSLog.dataEncryption, type: .error)
            return nil
        }
        
        guard let encryptedData = try? AESCrypto().encrypt(data: payloadData, key: decodedKeyData, iv: decodedIVData, padding: false) else {
            os_log("PostboxData encripting error -- ", log: OSLog.dataEncryption, type: .error)
            return nil
        }
        
        return encryptedData
    }
    
    private func constructProofSection(for payload: [String: Any]) -> [String: Any]? {
        
        guard let contact = contact else { return nil }
        guard DataStore.shared.userKeyPairs.count > 0 else {
            os_log("Construct proof section error -- empty data store", log: OSLog.consentReceiptGeneration, type: .info)
            return nil
        }
        
        var proofDictionary = [String : String]()
        var requiredConcentReceiptDict = payload
        // add values before sign
        proofDictionary["created"] = Date.stringForDate(date: Date())
        proofDictionary["type"] = proofTypeValue
        
        guard let keyPairPublicKey = contact.associatedKey?.publickey, let privateKey = contact.associatedKey?.privatekey else {
            return nil
        }
        
        guard //let requiredUserPublicKey = keyPairPublicKey,
            let requiredUserPublicKeyData = keyPairPublicKey.base64EncodedData() else {
                os_log("Construct proof section error -- We don't have the public key that we need", log: OSLog.consentReceiptGeneration, type: .info)
                return nil
            }
        
        proofDictionary["creator"] = requiredUserPublicKeyData.base64EncodedString()
        requiredConcentReceiptDict["proof"] = proofDictionary
        let signedDataString = signConcentReceipt(concentReceipt: requiredConcentReceiptDict, withPrivateKey: privateKey)
        // get "proof" dict
        guard var proofResultDictionary = requiredConcentReceiptDict["proof"] as? [String: Any] else {
            return nil
        }
        // add "encodedDataString" to the proof
        proofResultDictionary["signatureValue"] = signedDataString
        // set updated "proof" dict
        requiredConcentReceiptDict["proof"] = proofResultDictionary
        
        return requiredConcentReceiptDict
    }
    
    private func signConcentReceipt(concentReceipt: [String: Any], withPrivateKey key: String) -> String? {
        
        guard let unsignedConsentJSONData = try? JSONSerialization.data(withJSONObject: concentReceipt, options: [.sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]) as CFData else {
            os_log("Concent receipt signing error -- JSONSerialization data error", log: OSLog.consentReceiptGeneration, type: .error)
            return nil
        }
        
        guard let requiredKey = try? KeyGen.getCryptographicKey(for: key) else {
            os_log("Private key generation error -- %{public}@", log: OSLog.consentReceiptGeneration, type: .error)
            return nil
        }
        
        var error: Unmanaged<CFError>?
        guard let dataSignature = SecKeyCreateSignature(requiredKey,
                                                        SecKeyAlgorithm.rsaSignatureMessagePSSSHA256,
                                                        unsignedConsentJSONData,
                                                        &error) else {
            os_log("Digital signature generation error -- %{public}@", log: OSLog.consentReceiptGeneration, type: .error, error.debugDescription)
            
            error?.release()
            return nil
        }
        
        error?.release()
        let requiredData = dataSignature as Data
        
        return requiredData.base64EncodedString(options: [])
    }
}
