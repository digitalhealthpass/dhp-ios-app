//
//  ContactConsentTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import SafariServices
import os.log

extension OSLog {
    static let consentReceiptGeneration = OSLog(subsystem: subsystem, category: "consentReceipt")
    static let dataEncryption = OSLog(subsystem: subsystem, category: "dataEncryption")
}

class ContactConsentTableViewController: UITableViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        let refreshBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        navigationItem.rightBarButtonItem = refreshBarButtonItem
        
        tableView.isUserInteractionEnabled = true
        activityIndicator.stopAnimating()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? CustomNavigationController,
           let contactUploadTableViewController = navigationController.viewControllers.first as? ContactUploadTableViewController,
           let encryptedCredentialString = sender as? String {
            contactUploadTableViewController.uploadedPackages = uploadedPackages
            contactUploadTableViewController.selectedPackages = selectedPackages
            contactUploadTableViewController.contact = contact
            
            contactUploadTableViewController.baseUrl = nil //contact?.profileCredential?.credentialSubject?.technical?.poBox?.url
            
            contactUploadTableViewController.linkId = getLinkId()
            contactUploadTableViewController.password = getPassword()
            contactUploadTableViewController.name = getName()
            
            contactUploadTableViewController.encryptedCredentialString = encryptedCredentialString
        }
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var contact: Contact?
    
    var uploadedPackages: [Package]?
    
    var selectedPackages = [Package]()
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    private let unwindToContactDetailsSegue = "unwindToContactDetails"
    private let showContactUploadSegue = "showContactUpload"
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // FIXME: Need move to the place with constant
    private let proofTypeValue = "CKM_SHA256_RSA_PKCS_PSS"
}

// MARK: Private Methods
private extension ContactConsentTableViewController {
    
    private func getConsentInfo() {
        let orgId = (contact?.profilePackage?.credential?.extendedCredentialSubject?.rawDictionary?["orgId"] as? String) ?? String("nih") //Fallback to nih if the orgID is not available
        let holderId = contact?.associatedKey?.publickey?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        
        self.tableView.isUserInteractionEnabled = false
        self.activityIndicator.startAnimating()
        
        SchemaService().getConsentReceiptSchemaFor(regEntity: orgId, holderId: holderId) { result in
            DispatchQueue.main.async {
                self.tableView.isUserInteractionEnabled = true
                self.activityIndicator.stopAnimating()
            }
            
            switch result {
            case let .success(data):
                guard let payload = data["payload"] as? [String : Any], !(payload.isEmpty) else {
                    os_log("Generate consent receipt missing payload", log: OSLog.consentReceiptGeneration, type: .info)
                    self.handleConsentInfoError()
                    return
                }
                
                let consentInfo = ConsentInfo(value: payload)
                guard let encryptedCredentialString = self.getBase64EncryptedString(with: consentInfo) else {
                    self.handleConsentInfoError()
                    return
                }
                
                self.performSegue(withIdentifier: self.showContactUploadSegue, sender: encryptedCredentialString)
                
            case .failure(let error):
                os_log("Generate consent receipt error", log: OSLog.consentReceiptGeneration, type: .info)
                self.handleConsentInfoError(error: error)
            }
        }
    }

    private func handleConsentInfoError(error: Error? = nil) {
        let errorTitle = "contact.consentFailed.title".localized
        var errorMessage = "contact.consentFailed.message".localized
        
        if let err = error as NSError? {
            let domain = err.domain.isEmpty ? "Domain=Unknown" : "Domain=\(err.domain)"
            let code = "Code=\(err.code)"
            
            errorMessage = errorMessage + String("\n\n(\(domain) | \(code))")
        }

        showConfirmation(title: errorTitle,
                         message: errorMessage,
                         actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)]) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    private func getBase64EncryptedString(with consentInfo: ConsentInfo) -> String? {
        
        let consentReceiptDictionary = constructConsentReceipt(with: consentInfo)
        
        guard let encryptedData = getEncryptedData(consentReceipt: consentReceiptDictionary) else {
            return nil
        }
        
        let base64EncryptedString = encryptedData.base64EncodedString()
        return base64EncryptedString
    }
    
    private func constructConsentReceipt(with consentInfo: ConsentInfo) -> [String: Any] {
        var consentReceiptDictionary = consentInfo.rawDictionary ?? [String: Any]()
        
        consentReceiptDictionary["consentTimestamp"] = consentInfo.rawDictionary?["consentTimestamp"] as? Int
        consentReceiptDictionary["collectionMethod"] = "contact.dataSubjectInitiated".localized
        
        consentReceiptDictionary["consentReceiptID"] = consentInfo.rawDictionary?["consentReceiptID"] as? String
        
        consentReceiptDictionary["consentId"] = consentInfo.rawDictionary?["consentId"] as? String
        
        return consentReceiptDictionary
    }

    private func getEncryptedData(consentReceipt: [String: Any]) -> Data? {
        var consentReceiptDictionary = consentReceipt
        
        let symmetricKey = getSymmetricKey()
        
        guard let decodedIVData = symmetricKey?.iv?.base64DecodedData() else {
            os_log("IVData decoding error -- ", log: OSLog.dataEncryption, type: .error)
            return nil
        }
        
        guard let decodedKeyData = symmetricKey?.value?.base64DecodedData() else {
            os_log("KeyData decoding error -- ", log: OSLog.dataEncryption, type: .error)
            return nil
        }
        
        let credentialsDictionary: [Any] = selectedPackages.compactMap { $0.verifiableObject?.uploadData }
        let contactIdDictionary = constructContactId()
        
        // sign consent receipt here for separate logic
        guard let requiredConsentReceiptDictionary = constructProofSection(forConsentReceipt: consentReceiptDictionary) else {
            os_log("Proof section constructing error -- ", log: OSLog.dataEncryption, type: .error)
            return nil
        }
        
        consentReceiptDictionary = requiredConsentReceiptDictionary
        
        var postboxDictionary: [Any] = credentialsDictionary
        postboxDictionary.insert(consentReceiptDictionary, at: 0)
        postboxDictionary.insert(contactIdDictionary, at: 0)
        
        guard let postboxJSONData = try? JSONSerialization.data(withJSONObject: postboxDictionary, options: [.sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]) as Data else {
            os_log("Postbox dictionary serialization error -- JSONSerialization data error", log: OSLog.dataEncryption, type: .error)
            return nil
        }
        
        guard let postboxRawString = String(data: postboxJSONData, encoding: .utf8) else {
            os_log("PostboxJSONData encoding error -- ", log: OSLog.dataEncryption, type: .error)
            return nil
        }
        
        guard let postboxData = postboxRawString.data(using: .utf8) else {
            os_log("PostboxRawString converting to data error -- ", log: OSLog.dataEncryption, type: .error)
            return nil
        }
        
        guard let encryptedData = try? AESCrypto().encrypt(data: postboxData, key: decodedKeyData, iv: decodedIVData, padding: false) else {
            os_log("PostboxData encripting error -- ", log: OSLog.dataEncryption, type: .error)
            return nil
        }
        
        return encryptedData
    }

    private func getSymmetricKey() -> POBoxSymmetricKey? {
        return contact?.profileCredential?.extendedCredentialSubject?.technical?.poBox?.symmetricKey
        ?? contact?.profileCredential?.extendedCredentialSubject?.technical?.symmetricKey
    }
           
    private func constructContactId() -> [String: Any] {
        let contactIdDictionary = contact?.idCredential?.rawDictionary ?? [String: Any]()
        return contactIdDictionary
    }

    private func constructProofSection(forConsentReceipt consentReceipt: [String: Any]) -> [String: Any]? {
        
        guard DataStore.shared.userKeyPairs.count > 0 else {
            os_log("Construct proof section error -- empty data store", log: OSLog.consentReceiptGeneration, type: .info)
            return nil
        }
        
        var proofDictionary = [String : String]()
        var requiredConsentReceiptDict = consentReceipt
        // add values before sign
        proofDictionary["created"] = Date.stringForDate(date: Date())
        proofDictionary["type"] = proofTypeValue
        
        var keyPair: AsymmetricKeyPair?
        
        // checking that we are using the correct keys
        if let principal = consentReceipt["principal"] as? [String: Any] {
            keyPair = DataStore.shared.userKeyPairs.first(where: { $0.publickey == (principal["id"] as? String)?.removingPercentEncoding})
        } else {
            keyPair = DataStore.shared.userKeyPairs.first(where: { $0.publickey == (consentReceipt["piiPrincipalId"] as? String)?.removingPercentEncoding})
        }
        
        guard keyPair != nil else {
            os_log("Construct proof section error -- We don't have the keys we need", log: OSLog.consentReceiptGeneration, type: .info)
            return nil
        }
        
        let altKeyPair = DataStore.shared.userKeyPairs.first(where: { $0.publickey != nil && $0.privatekey != nil })
        
        let keyPairPrivateKey = keyPair?.rawDictionary?["privatekey"] as? String ?? altKeyPair?.privatekey
        
        guard let privateKey = keyPairPrivateKey else {
            os_log("Construct proof section error -- We don't have the private key that we need", log: OSLog.consentReceiptGeneration, type: .info)
            return nil
        }
        
        let keyPairPublicKey = keyPair?.publickey ?? altKeyPair?.publickey
        
        guard let requiredUserPublicKey = keyPairPublicKey,
              let requiredUserPublicKeyData = requiredUserPublicKey.base64EncodedData() else {
                  os_log("Construct proof section error -- We don't have the public key that we need", log: OSLog.consentReceiptGeneration, type: .info)
                  return nil
              }
        
        proofDictionary["creator"] = requiredUserPublicKeyData.base64EncodedString()
        requiredConsentReceiptDict["proof"] = proofDictionary
        let signedDataString = signConsentReceipt(consentReceipt: requiredConsentReceiptDict, withPrivateKey: privateKey)
        // get "proof" dict
        guard var proofResultDictionary = requiredConsentReceiptDict["proof"] as? [String: Any] else {
            return nil
        }
        // add "encodedDataString" to the proof
        proofResultDictionary["signatureValue"] = signedDataString
        // set updated "proof" dict
        requiredConsentReceiptDict["proof"] = proofResultDictionary
        
        return requiredConsentReceiptDict
    }

    private func signConsentReceipt(consentReceipt: [String: Any], withPrivateKey key: String) -> String? {
        
        guard let unsignedConsentJSONData = try? JSONSerialization.data(withJSONObject: consentReceipt, options: [.sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]) as CFData else {
            os_log("Consent receipt signing error -- JSONSerialization data error", log: OSLog.consentReceiptGeneration, type: .error)
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
    
    private func getLinkId() -> String {
        return contact?.profileCredential?.extendedCredentialSubject?.technical?.poBox?.linkId
        ?? contact?.profileCredential?.extendedCredentialSubject?.technical?.upload?.linkId
        ?? String()
    }
    
    private func getPassword() -> String {
        return contact?.profileCredential?.extendedCredentialSubject?.technical?.poBox?.passcode
        ?? contact?.profileCredential?.extendedCredentialSubject?.technical?.upload?.passcode
        ?? String()
    }
    
    private func getName() -> String {
        let piiController = contact?.profileCredential?.extendedCredentialSubject?.consentInfo?.piiControllers?.first?.piiController ?? String("Untitled")
        let dateString = Date.stringForDate(date: Date())
        let name = String(format: "%@_%@", piiController, dateString)
        
        return name
    }
        
}

extension ContactConsentTableViewController {
    
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "contact.credentials.selected".localized
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            if let servicesCount = (contact?.profileCredential?.extendedCredentialSubject?.rawDictionary?["services"] as? [[String: Any]])?.count {
                return servicesCount * 3
            } else if let servicesCount = contact?.profileCredential?.extendedCredentialSubject?.consentInfo?.services?.count {
                return servicesCount * 3
            }
            
            return 0
        } else if section == 1 {
            return selectedPackages.count
        }
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if let services = (contact?.profileCredential?.extendedCredentialSubject?.rawDictionary?["services"] as? [[String: Any]]) {
                let row = indexPath.row/3
                let service = services[row]
                
                if indexPath.row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ConsentServiceCell", for: indexPath)
                    cell.detailTextLabel?.text = service["service"] as? String ?? String("-")
                    
                    cell.textLabel?.font = AppFont.bodyScaled
                    cell.detailTextLabel?.font = AppFont.bodyScaled
                    
                    return cell
                } else if indexPath.row == 1 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ConsentCategoryCell", for: indexPath)
                    cell.detailTextLabel?.text = service["category"] as? String ?? String("-")
                    
                    cell.textLabel?.font = AppFont.bodyScaled
                    cell.detailTextLabel?.font = AppFont.bodyScaled
                    
                    return cell
                } else if indexPath.row == 2 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ConsentPurposeCell", for: indexPath)
                    let purposesArray = service["purposes"] as? [[String: Any]]
                    let purposes = purposesArray?.compactMap { $0["purpose"] as? String }
                    let purposeString = purposes?.joined(separator: ".\n")
                    cell.detailTextLabel?.text = purposeString ?? String("-")
                    
                    cell.textLabel?.font = AppFont.bodyScaled
                    cell.detailTextLabel?.font = AppFont.footnoteScaled
                    
                    return cell
                }
            } else if let service = contact?.profileCredential?.extendedCredentialSubject?.consentInfo?.services {
                let row = indexPath.row/3
                let service = service[row]
                let purpose = service.purposes
                
                if indexPath.row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ConsentServiceCell", for: indexPath)
                    let service = service.service
                    cell.detailTextLabel?.text = service ?? String("-")
                    
                    cell.textLabel?.font = AppFont.bodyScaled
                    cell.detailTextLabel?.font = AppFont.bodyScaled
                    
                    return cell
                } else if indexPath.row == 1 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ConsentCategoryCell", for: indexPath)
                    let categories = purpose?.compactMap { $0.purposeCategory }
                    let categoryString = categories?.joined(separator: ", ")
                    cell.detailTextLabel?.text = categoryString ?? String("-")
                    
                    cell.textLabel?.font = AppFont.bodyScaled
                    cell.detailTextLabel?.font = AppFont.bodyScaled
                    
                    return cell
                } else if indexPath.row == 2 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ConsentPurposeCell", for: indexPath)
                    let purposes = purpose?.compactMap { $0.purpose }
                    let purposeString = purposes?.joined(separator: ".\n")
                    cell.detailTextLabel?.text = purposeString ?? String("-")
                    
                    cell.textLabel?.font = AppFont.bodyScaled
                    cell.detailTextLabel?.font = AppFont.footnoteScaled
                    
                    return cell
                }
            }
        } else if indexPath.section == 1, let cell = tableView.dequeueReusableCell(withIdentifier: "ConsentCredentialCell", for: indexPath) as? ContactCredentialTableViewCell {
            let package = selectedPackages[indexPath.row]
            cell.populateCell(with: package, isSelected: false)
            return cell
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ConsentAcceptCell", for: indexPath)
            cell.textLabel?.font = AppFont.bodyScaled
            return cell
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        generateImpactFeedback()
        
        if indexPath.section == 2 {
            self.getConsentInfo()
        }
    }
}

extension String {
    //: ### Base64 encoding a string
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        
        return nil
    }
    
    //: ### Base64 decoding a string
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) {
            return String(data: data, encoding: .utf8)
        }
        
        return nil
    }
    
    func base64EncodedData() -> Data? {
        return self.data(using: .utf8)
    }
    
    func base64DecodedData() -> Data? {
        return Data(base64Encoded: self, options: .ignoreUnknownCharacters)
    }
}
