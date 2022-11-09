//
//  ContactDetailsTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import MessageUI
import SafariServices
import QRCoder
import os.log

extension OSLog {
    static let contactDetails = OSLog(subsystem: subsystem, category: "contactDetails")
}

protocol ContactDetailsTableViewControllerDelegate: AnyObject {
    func didSelectCall()
    func didSelectEmail()
    func didSelectWebsite()
}

class ContactDetailsTableViewController: UITableViewController {
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initActivityIndicator()
        
        tableView.separatorColor = UIColor(white: 0.85, alpha: 1.0)
        tableView.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didRefreshKeychain(notification:)),
                                               name: ProfileTableViewController.RefreshKeychainIdentifier,
                                               object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard uploadFlow else { return }
        performSegue(withIdentifier: showContactCredentialsSegue, sender: nil)
        uploadFlow = false
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var activityIndicatorView: UIView?
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    // MARK: Internal Properties
    
    var uploadFlow: Bool = false
    
    var contact: Contact? {
        didSet {
            uploadedPackages = contact?.uploadedPackages
            downloadedPackages = contact?.downloadedPackages
            
            self.prepareForIDFields()
            self.prepareForProfileFields()
        }
    }
    
    var uploadedPackages: [Package]? {
        didSet {
            if let uploadedPackages = uploadedPackages, uploadedPackages.count > 0 {
                numberOfRowsForUploadedCredential = uploadedPackages.count + 1
            } else {
                numberOfRowsForUploadedCredential = 1
            }
            
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    var downloadedPackages: [Package]? {
        didSet {
            if let downloadedPackages = downloadedPackages, downloadedPackages.count > 0 {
                numberOfRowsForDownloadedCredential = downloadedPackages.count + 1
            } else {
                numberOfRowsForDownloadedCredential = 1
            }
            
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let keyPairDetailsTableViewController = segue.destination as? KeyPairDetailsTableViewController {
            keyPairDetailsTableViewController.keyPair = contact?.associatedKey
        } else if let contactCredentialTableViewController = segue.destination as? ContactCredentialTableViewController {
            contactCredentialTableViewController.uploadedPackages = uploadedPackages
            contactCredentialTableViewController.contact = contact
        } else if let navigationController = segue.destination as? CustomNavigationController,
                  let credentialDetailsTableViewController = navigationController.viewControllers.first as? CredentialDetailsTableViewController, let package = sender as? Package {
            credentialDetailsTableViewController.package = package
        } else if let navigationController = segue.destination as? CustomNavigationController,
                  let scanCompleteViewController = navigationController.viewControllers.first as? ScanCompleteViewController {
            scanCompleteViewController.credentialString = sender as? String ?? String()
        } else if let navigationController = segue.destination as? CustomNavigationController,
                  let contactDownloadTableViewController = navigationController.viewControllers.first as? ContactDownloadTableViewController {
            contactDownloadTableViewController.contact = contact
        } else if segue.identifier == showAssociatedDataSegue, let associatedDataController = segue.destination as? AssociatedDataViewController {
            associatedDataController.contact = contact
        } else if let navigationController = segue.destination as? CustomNavigationController,
                  let deleteConnectionTableViewController = navigationController.viewControllers.first as? DeleteConnectionTableViewController {
            deleteConnectionTableViewController.contact = contact
        }
    }
    
    @IBAction func unwindToContactDetails(segue: UIStoryboardSegue) {
        uploadedPackages = contact?.uploadedPackages
    }
    
    @objc
    func didRefreshKeychain(notification: Notification) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    // MARK: - Internal Properties
    internal let showKeyPairDetailsSegue = "showKeyPairDetails"
    internal let showContactCredentialsSegue = "showContactCredentials"
    internal let showCredentialDetailsSegue = "showCredentialDetails"
    internal let showDownloadUpload = "showDownloadUpload"
    internal let showAssociatedDataSegue = "showAssociatedData"
    
    internal var numberOfRowsForUploadedCredential = 1
    internal var numberOfRowsForDownloadedCredential = 1
    
    var idFields = [Field]()
    var profileFields = [Field]()
    
    // MARK: - Internal Methods
    
    internal func deleteContact() {
        guard let contact = self.contact else { return }
        
        if contact.contactInfoType == .download {
            self.showConfirmation(title: "contact.delete.title".localized, message: "contact.delete.message".localized,
                                  actions: [("cred.delete.title".localized, IBMAlertActionStyle.destructive),
                                            ("button.title.cancel".localized, IBMAlertActionStyle.cancel)],
                                  completion: { index in
                if index == 0 {
                    self.offBoardContact(contact)
                }
            })
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        } else {
            self.performSegue(withIdentifier: "showRevoke", sender: nil)
        }
    }
    
    internal func showActivityIndicator() {
        activityIndicatorView?.isHidden = false
    }
    
    internal func hideActivityIndicator() {
        activityIndicatorView?.isHidden = true
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Methods
    
    private func prepareForIDFields() {
        let credentialSubjectDictionary = contact?.idPackage?.credential?.extendedCredentialSubject?.rawDictionary ?? [String: Any]()
        let schemaDictionary = contact?.idPackage?.schema?.schema ?? [String: Any]()
        
        let allUnsortedFields = SchemaParser().getVisibleFields(for: credentialSubjectDictionary, and: schemaDictionary)
        let unsortedFilteredFields = allUnsortedFields.filter { $0.visible ?? true }
        idFields = unsortedFilteredFields.sorted(by: { $0.path < $1.path })
    }
    
    private func prepareForProfileFields() {
        let credentialSubjectDictionary = contact?.profilePackage?.credential?.extendedCredentialSubject?.rawDictionary ?? [String: Any]()
        let schemaDictionary = contact?.profilePackage?.schema?.schema ?? [String: Any]()
        
        let allUnsortedFields = SchemaParser().getVisibleFields(for: credentialSubjectDictionary, and: schemaDictionary)
        let unsortedFilteredFields = allUnsortedFields.filter { $0.visible ?? false }
        profileFields = unsortedFilteredFields.sorted(by: { $0.path < $1.path })
    }
    
    private func offBoardContact(_ contact: Contact) {
        let orgId = contact.getOrganizationId()
        let contactId = contact.idPackage?.credential?.extendedCredentialSubject?.id ?? String()
        
        self.showActivityIndicator()
        
        DataSubmissionService().offBoardContact(for: orgId, contactId: contactId) { result in
            switch result {
            case .success:
                
                DataStore.shared.deleteContact(contact) { deleteResult in
                    switch deleteResult {
                    case .success:
                        os_log("[Success] - DeleteCard", log: OSLog.contactDetails, type: .info)
                    case .failure:
                        os_log("[FAIL] - DeleteCard from DataStore error", log: OSLog.contactDetails, type: .error)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        self.hideActivityIndicator()
                        self.generateNotificationFeedback(.success)
                        DataStore.shared.loadUserData()
                        self.performSegue(withIdentifier: "unwindToWallet", sender: nil)
                    }
                }
            case .failure:
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
        }
    }
}

private extension ContactDetailsTableViewController {
    
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

extension ContactDetailsTableViewController {
    
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if contact?.contactInfoType == .pobox {
            return numberOfSectionsPOBox(in: tableView)
        } else {
            return numberOfSectionsConnection(in: tableView)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if contact?.contactInfoType == .pobox {
            return tableViewPOBox(tableView, titleForHeaderInSection: section)
        } else {
            return tableViewConnection(tableView, titleForHeaderInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if contact?.contactInfoType == .pobox {
            return tableViewPOBox(tableView, numberOfRowsInSection: section)
        } else {
            return tableViewConnection(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if contact?.contactInfoType == .pobox {
            return tableViewPOBox(tableView, cellForRowAt: indexPath)
        } else {
            return tableViewConnection(tableView, cellForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if contact?.contactInfoType == .pobox {
            return tableViewPOBox(tableView, didSelectRowAt: indexPath)
        } else {
            return tableViewConnection(tableView, didSelectRowAt: indexPath)
        }
    }
}

extension ContactDetailsTableViewController: ContactDetailsTableViewControllerDelegate {
    // ======================================================================
    // === ContactDetailsTableViewControllerDelegate ========================
    // ======================================================================
    
    // MARK: - ContactDetailsTableViewControllerDelegate
    
    func didSelectCall() {
        generateImpactFeedback()
        
        var phone: String?
        
        if contact?.contactInfoType == .pobox {
            phone = contact?.profileCredential?.extendedCredentialSubject?.consentInfo?.piiControllers?.first?.phone
        } else {
            phone = contact?.profileCredential?.extendedCredentialSubject?.rawDictionary?["phone"] as? String
        }
        
        if let phone = phone, let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    func didSelectEmail() {
        generateImpactFeedback()
        
        var email: String?
        
        if contact?.contactInfoType == .pobox {
            email = contact?.profileCredential?.extendedCredentialSubject?.consentInfo?.piiControllers?.first?.email
        } else {
            email = contact?.profileCredential?.extendedCredentialSubject?.rawDictionary?["contact"] as? String
        }
        
        if let email = email, isValidEmail(email) {
            let mailComposeViewController = MFMailComposeViewController()
            mailComposeViewController.mailComposeDelegate = self
            mailComposeViewController.setToRecipients([email])
            present(mailComposeViewController, animated: true, completion: nil)
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func didSelectWebsite() {
        generateImpactFeedback()
        
        var urlString: String?
        
        if contact?.contactInfoType == .pobox {
            urlString = contact?.profileCredential?.extendedCredentialSubject?.consentInfo?.piiControllers?.first?.piiControllerUrl
        } else {
            urlString = contact?.profileCredential?.extendedCredentialSubject?.rawDictionary?["website"] as? String
        }
        
        if let piiControllerUrlString = urlString,
           let piiControllerUrl = URL(string: piiControllerUrlString) {
            
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true
            
            let safariViewController = SFSafariViewController(url: piiControllerUrl, configuration: config)
            present(safariViewController, animated: true)
        }
    }
}

extension ContactDetailsTableViewController: MFMailComposeViewControllerDelegate {
    // ======================================================================
    // === MFMailComposeViewControllerDelegate ========================
    // ======================================================================
    
    // MARK: - MFMailComposeViewControllerDelegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
