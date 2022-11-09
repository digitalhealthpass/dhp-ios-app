//
//  AssociatedDataViewController.swift
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

class AssociatedDataViewController: UIViewController {
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        fetchAssociatedData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        getCOSFilesRequest?.cancel()
        getAllFilesRequest?.cancel()
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSourceSegue, let contactSourceViewController = segue.destination as? ContactSourceViewController {
            contactSourceViewController.associatedData = sender
        }
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var activityIndicatorView: UIView?
    @IBOutlet weak var tableView: UITableView!
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Properties
    let showSourceSegue = "showSource"
    var contact: Contact?
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private var COSFiles: [[Any]] = []
    private var OrgServiceFiles: [[String: Any]] = []
    
    private var getCOSFilesRequest: DataRequest?
    private var getAllFilesRequest: DataRequest?
    private var numberOfSections = 0
    
    private var tableViewBackgroundView: UIView {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        label.text = "No Data"
        label.numberOfLines = 0
        label.font = AppFont.largeTitleScaled
        label.textColor = .secondaryLabel
        label.textAlignment = NSTextAlignment.center
        return label
    }
}

// ======================================================================
// === UITableView ==============================================
// ======================================================================

// MARK: - UITableViewDataSource
extension AssociatedDataViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return contact?.contactInfoType == .download ? OrgServiceFiles.count : COSFiles.first?.count ?? 0
        } else if section == 2 {
            return OrgServiceFiles.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AssocciatedDataTableViewCell", for: indexPath) as? AssocciatedDataTableViewCell else {
            return UITableViewCell()
        }
        
        if indexPath.section == 0 {
            cell.text = "View Source"
            cell.accessoryType = .none
        } else {
            cell.textLabel?.text = "Record \(indexPath.row + 1)"
            cell.textLabel?.textColor = .label
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return contact?.contactInfoType == .download ? "Postbox Records" : "Owner Records"
        } else if section == 2 {
            return "Postbox Records"
        }
        
        return nil
    }
    
}

// MARK: - UITableViewDelegate
extension AssociatedDataViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            if contact?.contactInfoType == .both {
                performSegue(withIdentifier: showSourceSegue, sender: [COSFiles, OrgServiceFiles])
            } else {
                performSegue(withIdentifier: showSourceSegue, sender: contact?.contactInfoType == .download ? OrgServiceFiles : COSFiles)
            }
            
        } else if indexPath.section == 1 {
            performSegue(withIdentifier: showSourceSegue, sender: contact?.contactInfoType == .download ? OrgServiceFiles[indexPath.row] : COSFiles.first?[indexPath.row])
        } else if indexPath.section == 2 {
            performSegue(withIdentifier: showSourceSegue, sender: OrgServiceFiles[indexPath.row])
        }
    }
    
}

// MARK: Private Extension
private extension AssociatedDataViewController {
    
    func configure() {
        tableView.isHidden = true
        tableView.dataSource = self
        tableView.delegate = self
        
        activityIndicatorView?.layer.borderColor = UIColor.systemBlue.cgColor
        activityIndicatorView?.layer.shadowColor = UIColor.black.cgColor
        activityIndicatorView?.isAccessibilityElement = true
        
        let progressString = "accessibility.indicator.loading".localized
        activityIndicatorView?.accessibilityValue = progressString
        
        UIAccessibility.post(notification: .announcement, argument: progressString)
    }
    
    func getSignature() -> String? {
        guard let privateKey = contact?.associatedKey?.privatekey, let publicKey = contact?.associatedKey?.publickey else {
            return nil
        }
        
        let unsignedData = Data("{\"proof\":{\"creator\":\"\(publicKey)\"}}".utf8) as CFData
        
        guard let requiredKey = try? KeyGen.getCryptographicKey(for: privateKey) else {
            os_log("Private key generation error -- %{public}@", log: OSLog.contactDetails, type: .error)
            return nil
        }
        
        var error: Unmanaged<CFError>?
        guard let signedData = SecKeyCreateSignature(requiredKey, SecKeyAlgorithm.rsaSignatureMessagePSSSHA256, unsignedData, &error) else {
            os_log("Digital signature generation error -- %{public}@", log: OSLog.contactDetails, type: .error, error.debugDescription)
            error?.release()
            return nil
        }
        error?.release()
        
        return (signedData as Data).base64EncodedString(options: [])
    }
    
    func updateView() {
        self.navigationItem.title = "Associated Data"
        self.activityIndicatorView?.isHidden = true
        
        if (contact?.contactInfoType != .download && COSFiles.isEmpty && OrgServiceFiles.isEmpty)
            || (contact?.contactInfoType == .download  && OrgServiceFiles.isEmpty)  {
            tableView.backgroundView = tableViewBackgroundView
            numberOfSections = 0
        } else {
            tableView.backgroundView = nil
            numberOfSections = (COSFiles.isEmpty || OrgServiceFiles.isEmpty) ? 2 : 3
        }
        
        tableView.isHidden = false
        tableView.reloadData()
    }
    
    func fetchAssociatedData() {
        self.navigationItem.title = "result.loading".localized
        
        //For download only flow, call AllFiles
        //For any other flow, call AllFiles and COSFiles
        if contact?.contactInfoType == .download {
            let linkID = contact?.profilePackage?.credential?.extendedCredentialSubject?.technical?.download?.linkId ?? String()
            let passcode = contact?.profilePackage?.credential?.extendedCredentialSubject?.technical?.download?.passcode ?? String()
            
            let fetchAll = self.fetchAllFiles(for: linkID, with: passcode)
            
            let _ = when(fulfilled: [fetchAll])
                .done { _ in
                    self.updateView()
                }
        } else {
            let ordID = (contact?.profilePackage?.credential?.extendedCredentialSubject?.rawDictionary?["orgId"] as? String) ?? String("nih") //Fallback to nih if the orgID is not available
            let holderID = contact?.associatedKey?.publickey ?? String()
            let signature = getSignature() ?? String()
            
            let linkID = contact?.profilePackage?.credential?.extendedCredentialSubject?.technical?.download?.linkId ?? contact?.profilePackage?.credential?.extendedCredentialSubject?.technical?.upload?.linkId ?? String()
            let passcode = contact?.profilePackage?.credential?.extendedCredentialSubject?.technical?.download?.passcode ?? contact?.profilePackage?.credential?.extendedCredentialSubject?.technical?.upload?.passcode ?? String()
            
            let fetchCOS = self.fetchCOSFiles(for: ordID, and: holderID, with: signature)
            let fetchAll = self.fetchAllFiles(for: linkID, with: passcode)
            
            let _ = when(fulfilled: [fetchCOS, fetchAll])
                .done { _ in
                    self.updateView()
                    self.navigationItem.title = "Associated Data"
                    self.activityIndicatorView?.isHidden = true
                }
        }
    }
    
    @discardableResult
    func fetchCOSFiles(for ordID: String, and holderID: String, with signature: String) -> Promise<Bool> {
        return Promise<Bool>(resolver: { resolver in
            self.getCOSFilesRequest = DataSubmissionService().getCOSFiles(for: ordID, and: holderID, with: signature) { result in
                switch result {
                case .success(let json):
                    guard let payload = json["payload"] as? [[Any]], !(payload.isEmpty) else {
                        self.COSFiles.removeAll()
                        resolver.fulfill(false)
                        return
                    }
                    
                    self.COSFiles = payload
                    resolver.fulfill(true)
                    
                case .failure(let error):
                    os_log("[FAIL] - All Cos Files For Holder %{public}@", log: OSLog.services, type: .error, error.localizedDescription)
                    self.COSFiles.removeAll()
                    resolver.fulfill(false)
                }
            }
        })
    }
    
    func parseFiles(for content: [[String : Any]]) -> [[String: Any]]? {
        let symmetricKey = self.contact?.profileCredential?.extendedCredentialSubject?.technical?.poBox?.symmetricKey ?? self.contact?.profileCredential?.extendedCredentialSubject?.technical?.symmetricKey ?? self.contact?.profileCredential?.extendedCredentialSubject?.technical?.upload?.symmetricKey ?? self.contact?.profileCredential?.extendedCredentialSubject?.technical?.download?.symmetricKey
        
        guard let decodedIVData = symmetricKey?.iv?.base64DecodedData(),
              let decodedKeyData = symmetricKey?.value?.base64DecodedData() else {
                  return nil
              }
        
        var filesForOrgServiceResult = [[String: Any]]()
        
        for var item in content {
            if let contentValue = item["content"] as? String,
               let contentData = contentValue.base64DecodedData() {
                
                if let decryptedData = try? AESCrypto().decrypt(data: contentData, key: decodedKeyData, iv: decodedIVData),
                   let jsonObject = try? JSONSerialization.jsonObject(with: decryptedData, options: []) as? [[String : Any]] {
                    
                    item["content"] = jsonObject
                }
            }
          
            filesForOrgServiceResult.append(item)
        }
        
        return filesForOrgServiceResult
    }
    
    @discardableResult
    func fetchAllFiles(for linkID: String, with passcode: String) -> Promise<Bool> {
        return Promise<Bool>(resolver: { resolver in
            self.getAllFilesRequest = PostboxService().getAllFiles(for: linkID, with: passcode) { result in
                switch result {
                case .success(let json):
                    guard let payload = json["payload"] as? [String: Any], !(payload.isEmpty),
                          let contentDictArray = payload["attachments"] as? [[String : Any]],
                          let files = self.parseFiles(for: contentDictArray) else {
                              os_log("[FAIL] - Get All Files Local Mapping problem", log: OSLog.services, type: .error)
                              self.OrgServiceFiles.removeAll()
                              resolver.fulfill(false)
                              return
                          }
                    
                    self.OrgServiceFiles =  self.contact?.contactInfoType == .download ? contentDictArray : files
                    resolver.fulfill(true)
                    
                case .failure(let error):
                    os_log("[FAIL] - All Files For Organization %{public}@", log: OSLog.services, type: .error, error.localizedDescription)
                    self.OrgServiceFiles.removeAll()
                    resolver.fulfill(false)
                }
            }
        })
    }
    
}
