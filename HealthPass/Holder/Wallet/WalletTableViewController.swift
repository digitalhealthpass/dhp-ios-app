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

enum OpenOptionsAction: String {
    case none = "none"
    
    case scanQRCode = "scanQRCode"
    case photosQRCode = "photosQRCode"
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
                scanCompleteViewController.credentialString = sender as? String ?? String()
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
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let replaceSnapshot = "replaceSnapshot"
    
    private let presentAddOptions = "presentAddOptions"
    
    private let presentScanComplete = "presentScanComplete"
    private let presentContactComplete = "presentContactComplete"
    
    private var credentialDetails: String { return (UIDevice.current.userInterfaceIdiom == .pad) ? replaceCredentialDetails : presentCredentialDetails }
    private let presentCredentialDetails = "presentCredentialDetails"
    private let replaceCredentialDetails = "replaceCredentialDetails"
    
    private var contactDetails: String { return (UIDevice.current.userInterfaceIdiom == .pad) ? replaceContactDetails : presentContactDetails }
    private let presentContactDetails = "presentContactDetails"
    private let replaceContactDetails = "replaceContactDetails"
    
    private let presentScan = "presentScan"
    
    private let presentNewRegistration = "presentNewRegistration"
    
    private var uploadFlow: Bool = false
    
    // MARK: Private Methods
    
    //    temporary helper function to read credentials JSON
    private func readCredentialsFile(forName name: String) -> [[String: Any]]? {
        do {
            if let filePath = Bundle.main.path(forResource: name, ofType: "json") {
                let fileUrl = URL(fileURLWithPath: filePath)
                let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
                let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                return jsonArray
            }
        } catch {
            print(error)
        }
        
        return []
    }
    
    @objc
    private func refreshKeychain(notification: Notification? = nil) {
        DataStore.shared.loadUserData()
        
        packageArray = DataStore.shared.userPackages
        contactsArray = DataStore.shared.userContacts
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
    
    private func showPhotoLibrary() {
        if DataStore.shared.cameraAccess {
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.delegate = self
            
            present(imagePickerController, animated: true, completion: nil)
        } else {
            showConfirmation(title: "wallet.cameraAccess.title".localized,
                             message: "wallet.cameraAccess.message".localized,
                             actions: [("button.title.dontallow".localized, IBMAlertActionStyle.cancel), ("button.title.ok".localized, IBMAlertActionStyle.default)]) { index in
                if index == 1 {
                    DataStore.shared.cameraAccess = true
                    self.showPhotoLibrary()
                }
            }
            
        }
    }
    
    private func showQRCodeDocumentDirectory(_ sender: UIBarButtonItem) {
        let importMenu = UIDocumentPickerViewController(documentTypes: [String(kUTTypeImage)], in: .import)
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        
        if let popoverPresentationController = importMenu.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender
        }
        
        present(importMenu, animated: true, completion: nil)
    }
    
}

extension WalletTableViewController {
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return SettingsBundleHelper.shared.savedEnvironment.canShowRegistration ? 2 : 1
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(40.0)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "WalletTableViewHeaderFooterView") as? WalletTableViewHeaderFooterView else {
            return nil
        }
        
        switch section {
        case 0:
            header.title = "wallet.section.cards".localized
            header.onAddDidTap = handelAddCardAction
        case 1:
            header.title = "wallet.section.connections".localized
            header.onAddDidTap = showNewRegistration
        default:
            return nil
        }
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat(20.0)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return isPackageEmpty ? 1 : packageArray.count
        case 1:
            return isContactEmpty ? 1 : contactsArray.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0  {
            
            guard !isPackageEmpty else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceholderCell", for: indexPath) as! PlaceholderTableViewCell
                cell.setupCell(with: .card)
                return cell
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "CredentialCardCell", for: indexPath) as! CredentialCardTableViewCell
            
            let package = packageArray[indexPath.row]
            cell.populateCell(with: package)
            
            if let selectedPackage = selectedObject as? Package,
               ((package.type == .VC || package.type == .IDHP || package.type == .GHP) && selectedPackage.credential?.id == package.credential?.id) ||
                ((package.type == .SHC) && selectedPackage.jws?.payloadString == package.jws?.payloadString) ||
                ((package.type == .DCC) && selectedPackage.cose?.payload.asData() == package.cose?.payload.asData()) {
                cell.selectedCell()
            } else {
                cell.resetCell()
            }
            
            return cell
            
        } else if indexPath.section == 1 {
            guard !isContactEmpty else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceholderCell", for: indexPath) as! PlaceholderTableViewCell
                cell.setupCell(with: .conection)
                return cell
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCardCell", for: indexPath) as! ContactCardTableViewCell
            
            let contact = contactsArray[indexPath.row]
            cell.populateCell(with: contact)
            
            if let selectedContact = selectedObject as? Contact, selectedContact.profileCredential?.id == contact.profileCredential?.id {
                cell.selectedCell()
            } else {
                cell.resetCell()
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            guard !isPackageEmpty else {
                return UITableView.automaticDimension
            }
            
            return CGFloat(220.0)
        } else if indexPath.section == 1 {
            guard !isContactEmpty else {
                return UITableView.automaticDimension
            }
            
            return CGFloat(90.0)
        }
        
        return CGFloat.zero
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        generateImpactFeedback()
        
        if indexPath.section == 0  {
            guard !isPackageEmpty else {
                self.handelAddCardAction()
                return
            }
            
            selectedObject = packageArray[indexPath.row]
            performSegue(withIdentifier: credentialDetails, sender: selectedObject)
        } else if indexPath.section == 1 {
            guard !isContactEmpty else {
                self.showNewRegistration()
                return
            }
            
            selectedObject = contactsArray[indexPath.row]
            performSegue(withIdentifier: contactDetails, sender: selectedObject)
        } else {
            selectedObject = nil
        }
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
}

extension WalletTableViewController {
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods
    
    private func showNewRegistration(org: String? = nil) {
        performSegue(withIdentifier: presentNewRegistration, sender: org)
    }
    
    private func readContactJSONFromFile(fileUrl: URL) -> [[String: Any]]? {
        do {
            let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
            return try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        } catch {
            return nil
        }
    }
    
    private func getContactTuple(from json: [[String: Any]]) -> (Credential, Credential)? {
        let credentials = json.compactMap { Credential(value: $0) }
        
        guard let profileCredentials = credentials.filter({ $0.extendedCredentialSubject?.type == "profile" }).first,
              let idCredentials = credentials.filter({ $0.extendedCredentialSubject?.type == "id" }).first else {
                  return nil
              }
        
        return (profileCredentials, idCredentials)
    }
}

extension WalletTableViewController {
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods
    
    private func showScanComplete(with image: UIImage?) {
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
    
    private func showScanComplete(with message: String?) {
        generateNotificationFeedback(.success)
        
        performSegue(withIdentifier: presentScanComplete, sender: message)
    }
    
    private func showErrorAlert(title: String, message: String) {
        generateNotificationFeedback(.error)
        
        showConfirmation(title: title, message: message, actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
    }
    
    // IBM RTO Reminder sections
    private func checkExistingConnections() {
        guard DataStore.shared.IBM_RTO_Reminder else {
            return
        }
        
        let filteredPackage = packageArray.filter({
            guard let type = $0.credential?.credentialSubject?["type"] as? String, DataStore.shared.IBM_RTO_CRED_TYPE_PROD.contains(type),
                  let schemaName = $0.schema?.name, DataStore.shared.IBM_RTO_SCHEMA_NAME_PROD.contains(schemaName),
                  let issuerName = $0.issuerMetadata?.name, DataStore.shared.IBM_RTO_ISSUER_NAME_PROD.contains(issuerName) else {
                      return false
                  }
            
            return true
        })
        
        guard !(filteredPackage.isEmpty) else {
            return
        }
        
        let filteredContacts = self.contactsArray.compactMap({ contact -> Contact? in
            if let contactOrganization = contact.idPackage?.credential?.credentialSubject?["organization"] as? String,
               contactOrganization == DataStore.shared.IBM_RTO_ORG_PROD {
                return contact
            }
            
            return nil
        })
        
        for contact in filteredContacts {
            guard let uploadedPackages = contact.uploadedPackages else {
                self.showReminderForExisting(contact)
                return
            }
            
            guard !(uploadedPackages.isEmpty) else {
                self.showReminderForExisting(contact)
                return
            }
        }
    }
    
    private func handleNewCredential(_ package: Package) {
        guard let type = package.credential?.credentialSubject?["type"] as? String, DataStore.shared.IBM_RTO_CRED_TYPE_PROD.contains(type),
              let schemaName = package.schema?.name, DataStore.shared.IBM_RTO_SCHEMA_NAME_PROD.contains(schemaName),
              let issuerName = package.issuerMetadata?.name, DataStore.shared.IBM_RTO_ISSUER_NAME_PROD.contains(issuerName) else {
                  return
              }
        
        let filteredContacts = self.contactsArray.compactMap({ contact -> Contact? in
            if let contactOrganization = contact.idPackage?.credential?.credentialSubject?["organization"] as? String,
               contactOrganization == DataStore.shared.IBM_RTO_ORG_PROD {
                return contact
            }
            
            return nil
        })
        
        for contact in filteredContacts {
            guard let uploadedPackages = contact.uploadedPackages else {
                self.showReminderForNew(contact)
                return
            }
            
            guard !(uploadedPackages.isEmpty) else {
                self.showReminderForNew(contact)
                return
            }
        }
    }
    
    private func handleNewConnection(_ contact: Contact) {
        guard uploadFlow else { return }
        
        performSegue(withIdentifier: self.contactDetails, sender: contact)
        uploadFlow = false
    }
    
    private func showReminderForExisting(_ contact: Contact) {
        showConfirmation(title: "wallet.share.ibmrto.title".localized,
                         message: "wallet.share.ibmrto.message2".localized,
                         actions: [ ("wallet.share.ibmrto.action.yes.share".localized, IBMAlertActionStyle.default),
                                    ("wallet.share.ibmrto.action.no".localized, IBMAlertActionStyle.destructive),
                                    ("wallet.share.ibmrto.action.later".localized, IBMAlertActionStyle.cancel) ]) { index in
            if index == 0 {
                self.performSegue(withIdentifier: self.contactDetails, sender: contact)
            } else if index == 1 {
                DataStore.shared.IBM_RTO_Reminder = false
            }
        }
    }
    
    private func showReminderForNew(_ contact: Contact) {
        self.showConfirmation(title: "wallet.share.ibmrto.title".localized,
                              message: "wallet.share.ibmrto.message1".localized,
                              actions: [ ("wallet.share.ibmrto.action.yes.share".localized, IBMAlertActionStyle.default),
                                         ("wallet.share.ibmrto.action.later".localized, IBMAlertActionStyle.cancel) ]) { index in
            if index == 0 {
                self.performSegue(withIdentifier: self.contactDetails, sender: contact)
            }
        }
    }
    
    private func handelAddCardAction() {
        generateImpactFeedback()
        
        performSegue(withIdentifier: presentAddOptions, sender: nil)
    }
    
    private func showNewRegistration() {
        generateImpactFeedback()
        
        performSegue(withIdentifier: presentNewRegistration, sender: nil)
    }
}

extension WalletTableViewController : UIDocumentPickerDelegate, UINavigationControllerDelegate {
    
    // ======================================================================
    // === UIDocumentPickerViewController ==================================
    // ======================================================================
    
    // MARK: - UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print("url = \(url)")
        let fileExtension = url.pathExtension as CFString
        if let uniformTypeIdentifier = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil) {
            let uniformTypeRetainedValue = uniformTypeIdentifier.takeRetainedValue()
            if UTTypeConformsTo(uniformTypeRetainedValue, kUTTypeImage), let data = try? Data(contentsOf: url) {
                let image = UIImage(data: data)
                showScanComplete(with: image)
            } else if UTTypeConformsTo(uniformTypeRetainedValue, kUTTypeJSON), let json = readContactJSONFromFile(fileUrl: url), let contactTuple = getContactTuple(from: json) {
                self.performSegue(withIdentifier: self.presentContactComplete, sender: contactTuple)
            }
        }  else {
            //TODO: handle JSON here
            self.generateNotificationFeedback(.error)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { }
}

extension WalletTableViewController: UIImagePickerControllerDelegate {
    
    // ======================================================================
    // === UIImagePickerController ==================================
    // ======================================================================
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        picker.dismiss(animated: true, completion: {
            self.showScanComplete(with: image)
        })
    }
    
}
