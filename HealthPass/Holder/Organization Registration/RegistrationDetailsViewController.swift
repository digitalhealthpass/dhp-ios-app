//
//  RegistrationDetailsViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

protocol RegistrationDetailsDelegate: AnyObject {
    func valueSelectList(for title: String?, and dictionary: [String: Any]?, value: String?, values: [String]?)
    func registrationTextValueUpdated(_ title: String, value: String)
}

class RegistrationDetailsViewController: UIViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.setHidesBackButton(true, animated: true)
        
        tableView.tableFooterView = UIView()
        finishButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        updateFooterView(complete: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
      
        setNeedsStatusBarAppearanceUpdate()
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    // MARK: - IBOutlet
    
    @IBOutlet weak var tableViewHeader: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var finishButton: UIButton!
    
    @IBOutlet weak var activityIndicatorView: UIView?
    
    // MARK: - IBAction
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onFinish(_ sender: Any) {
        completeRegistration()
    }
    
    // MARK: - Navigation
    
    @IBAction func unwindToRegistrationDetails(segue: UIStoryboardSegue) {
        if let valueSelectionTableViewController = segue.source as? ValueSelectionTableViewController {
            if let valueTitle = valueSelectionTableViewController.valueTitle {
                if let selectedData = valueSelectionTableViewController.selectedData {
                    dataSourceValue[valueTitle] = selectedData
                } else if let selectedArray = valueSelectionTableViewController.selectedArray {
                    dataSourceValue[valueTitle] = selectedArray
                }
            }
        }
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? CustomNavigationController,
           let valueSelectionTableViewController = navigationController.viewControllers.first as? ValueSelectionTableViewController {
            let multiple = sender as? (String?, [String: Any]?, String?, [String]?)
            valueSelectionTableViewController.valueTitle = multiple?.0
            valueSelectionTableViewController.valueDictionary = multiple?.1
            valueSelectionTableViewController.selectedData = multiple?.2
            valueSelectionTableViewController.selectedArray = multiple?.3
        }
    }
    
    // MARK: - NSNotification
    
    @objc
    private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        }
    }
    
    @objc
    private func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = .zero
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK:  Internal Properties
    
    var contactTuple: (Credential, Credential)?
    
    var orgId: String! {
        didSet {
            dataSourceValue["organization"] = orgId
        }
    }
    var registrationCode: String! {
        didSet {
            dataSourceValue["registrationCode"] = registrationCode
        }
    }
    var orgSchema: Schema? {
        didSet {
            constructDataSource()
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let showValueSelectionSegue = "showValueSelection"
    private let unwindToWalletSegue = "unwindToWallet"
    
    private var sortedKeys: [String]? {
        return dataSource.keys.sorted()
    }
    
    private var dataSourceValue = [String: Any]() {
        didSet {
            if shouldRefreshTableForDataSourceValue {
                UIView.performWithoutAnimation {
                    self.tableView?.reloadData()
                }
            }
        }
    }
    
    private var dataSource = [String: Any]() {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView?.reloadData()
            }
        }
    }
    
    private var generatedKeyPair: [String: Any?]? {
        didSet {
            updateView()
        }
    }
    
    private var didFinishLoading = false {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView?.reloadData()
            }
        }
    }
    
    private var tag: String?
    private var date: Date?
    private var shouldRefreshTableForDataSourceValue = true
    
    private var publickeySecString: String? {
        didSet {
            didFinishLoading = (publickeySecString != nil) && (privatekeySecString != nil)
            dataSourceValue["publicKey"] = publickeySecString
            dataSourceValue["id"] = self.publickeySecString
        }
    }
    private var publickeySecData: Data? {
        didSet {
            publickeySecString = publickeySecData?.base64EncodedString()
        }
    }
    
    private var privatekeySecString: String?{
        didSet {
            didFinishLoading = (publickeySecString != nil) && (privatekeySecString != nil)
        }
    }
    private var privatekeySecData: Data? {
        didSet {
            privatekeySecString = privatekeySecData?.base64EncodedString()
        }
    }
    
    // MARK: Private Methods
    
    private func updateFooterView(complete: Bool) {
        finishButton?.isEnabled = complete
        finishButton?.isUserInteractionEnabled = complete
        let backgroundColor = complete ? UIColor.systemBlue : UIColor.systemGray
        finishButton?.backgroundColor = backgroundColor
    }
    
    private func constructDataSource() {
        let schema = orgSchema?.rawDictionary?["schema"] as? [String: Any]
        let properties = schema?["properties"] as? [String: Any]
        
        dataSource = properties?.filter({ (element) -> Bool in
            if let value = element.value as? [String: Any] {
                let visible = (value["visible"] as? Bool) ?? true
                return visible
            }
            return false
        }) ?? [String: Any]()
        
        generateNewKeyPair()
    }
    
    private func readJSONFromFile(fileName: String) -> [[String: Any]]? {
        let components = fileName.components(separatedBy: ".")
        let resource = components.first ?? fileName
        let type = components.last ?? String("nihholder")
        
        if let path = Bundle.main.path(forResource: resource, ofType: type) {
            do {
                let fileUrl = URL(fileURLWithPath: path)
                let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
                return try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            } catch {
                return nil
            }
        }
        
        return nil
    }
    
    private func getContactTuple(from json: [[String: Any]]) -> (Credential, Credential)? {
        let credentials = json.compactMap { Credential(value: $0) }
        
        guard let profileCredentials = credentials.filter({ $0.extendedCredentialSubject?.type == "profile" }).first,
              let idCredentials = credentials.filter({ $0.extendedCredentialSubject?.type == "id" }).first else {
            return nil
        }
        
        return (profileCredentials, idCredentials)
    }
    
    private func completeRegistration() {
        guard let keypairDictionary = constructDictionary() else {
            return
        }
        
        activityIndicatorView?.isHidden = false
        view.isUserInteractionEnabled = false
        
        saveKeyPair(dictionary: keypairDictionary) { success in
            if success {
                let organizationId = self.orgId ?? "default"
                
                DataSubmissionService().register(for: organizationId, with: self.dataSourceValue) { result in
                    self.activityIndicatorView?.isHidden = true
                    self.view.isUserInteractionEnabled = true
                    
                    switch result {
                    case .success(let data):
                        guard let payload = data["payload"] as? [[String : Any]] else {
                            return
                        }
                        
                        self.contactTuple = self.getContactTuple(from: payload)
                        self.performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
                        
                        break
                    case .failure(let error):
                        self.handleRegistrationError(error: error)
                    }
                }
            } else {
                //TODO: Error handling here
                self.activityIndicatorView?.isHidden = true
                self.view.isUserInteractionEnabled = true
            }
        }
    }
    
    private func handleRegistrationError(error: Error? = nil) {
        let title = "reg.failed.title".localized
        var message = "reg.failed.message".localized
        
        if let err = error as NSError? {
            let domain = err.domain.isEmpty ? "Domain=Unknown" : "Domain=\(err.domain)"
            let code = "Code=\(err.code)"
            
            message = message + String("\n\n(\(domain) | \(code))")
        }

        self.showConfirmation(title: title,
                              message: message,
                              actions: [("Exit", IBMAlertActionStyle.destructive), ("reg.retry".localized, IBMAlertActionStyle.default)]) { index in
            if index == 0 {
                self.performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
            } 
        }
    }

}

extension RegistrationDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    
    // ======================================================================
    // === UITableView ======================================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedKeys?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let title = sortedKeys?[indexPath.row] else {
            return UITableViewCell()
        }
        
        guard let dictionary = dataSource[title] as? [String: Any] else {
            return UITableViewCell()
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RegistrationDetailsTableViewCell", for: indexPath) as? RegistrationDetailsTableViewCell else {
            return UITableViewCell()
        }
        
        var value = dataSourceValue[title] as? String
        let values = dataSourceValue[title] as? [String]
        if title.lowercased() == "key" {
            value = publickeySecString
        } else if title.lowercased() == "id" {
            value = registrationCode
        }
        
        cell.populateCell(title: title, dictionary: dictionary, value: value, values: values)
        cell.delegate = self
        
        return cell
    }
    
}

extension RegistrationDetailsViewController: RegistrationDetailsDelegate {
    
    // ======================================================================
    // === RegistrationDetailsViewController ================================
    // ======================================================================
    
    // MARK: - RegistrationDetailsDelegate
    
    func valueSelectList(for title: String?, and dictionary: [String: Any]?, value: String?, values: [String]?) {
        performSegue(withIdentifier: showValueSelectionSegue, sender: (title, dictionary, value, values))
    }
    
    func registrationTextValueUpdated(_ title: String, value: String) {
        shouldRefreshTableForDataSourceValue = false
        dataSourceValue[title] = value
        shouldRefreshTableForDataSourceValue = true
    }
}

extension RegistrationDetailsViewController {
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods
    
    private func generateNewKeyPair() {
        do {
            let keyTuple = try KeyGen.generateNewKeys(tag: registrationCode)
            self.generatedKeyPair = [ "publickey": keyTuple.publickey,
                                      "privatekey": keyTuple.privatekey,
                                      "tag": registrationCode,
                                      "timestamp" : Date() ]
        } catch {
            self.generatedKeyPair = nil
            self.generateNotificationFeedback(.error)
        }
    }
    
    private func updateView() {
        var dictionary: [String : Any?]?
        
        if let generatedKeyPair = generatedKeyPair {
            dictionary = generatedKeyPair
        }
        
        if let dictionary = dictionary {
            updateTag(for: dictionary)
            updateTimestamp(for: dictionary)
            updatePublic(for: dictionary)
            updatePrivate(for: dictionary)
        }
    }
    
    private func updateTag(for dictionary: [String : Any?]) {
        if let tag = dictionary["tag"] as? String, !tag.isEmpty {
            self.tag = tag
        }
    }
    
    private func updateTimestamp(for dictionary: [String : Any?]) {
        if let date = dictionary["timestamp"] as? Date {
            self.date = date
        }
    }
    
    private func updatePublic(for dictionary: [String : Any?]) {
        if let publickey = dictionary["publickey"] {
            let publickeySec = publickey as! SecKey
            self.publickeySecData = try? KeyGen.decodeKeyToData(publickeySec)
        }
    }
    
    private func updatePrivate(for dictionary: [String : Any?]) {
        if let privatekey = dictionary["privatekey"] {
            let privatekeySec = privatekey as! SecKey
            self.privatekeySecData = try? KeyGen.decodeKeyToData(privatekeySec)
        }
    }
    
    private func constructDictionary() -> [String: Any]? {
        var dictionary = [String: Any]()
        var id = String()
        
        if let tag = tag {
            dictionary["tag"] = tag
            id = String(format: "%@.%@", id, tag)
        }
        
        if let date = date {
            dictionary["timestamp"] = Date.stringForDate(date: date, dateFormatPattern: .keyGenFormat)
            id = String(format: "%@.%@", id, Date.stringForDate(date: date, dateFormatPattern: .timestampFormat))
        }
        
        if let publickey = publickeySecString {
            dictionary["publickey"] = publickey
        }
        
        if let privatekey = privatekeySecString {
            dictionary["privatekey"] = privatekey
        }
        
        dictionary["id"] = id
        
        return dictionary
    }
    
    private func saveKeyPair(dictionary: [String : Any], completion: ((_ success: Bool) -> Void)? = nil) {
        DataStore.shared.saveKeyPair(dictionary) { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                DataStore.shared.loadUserData()
                NotificationCenter.default.post(name: ProfileTableViewController.RefreshKeychainIdentifier, object: nil)
                let success = result.isSuccess
                completion?(success)
            }
        }
    }
    
}
