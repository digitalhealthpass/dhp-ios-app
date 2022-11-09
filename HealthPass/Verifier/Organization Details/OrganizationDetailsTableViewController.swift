//
//  OrganizationDetailsTableViewController.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import PromiseKit
import VerifiableCredential
import VerificationEngine

class OrganizationDetailsTableViewController: UITableViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        tableView.tableFooterView = UIView()
        
        let refreshBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        navigationItem.rightBarButtonItem = refreshBarButtonItem
        
        tableView.isUserInteractionEnabled = true
        activityIndicator.stopAnimating()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkNavigationItem()
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet var tableViewPlaceholder: UIView!
    
    // MARK: - IBAction
    
    @IBAction func onCancel(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindToScan", sender: nil)
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var credential: Credential? {
        didSet {
            processCredential()
        }
    }
    
    var package: Package? {
        didSet {
            self.prepareForTable()
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    private var schema: Schema?
    
    private var issuerMetadata: IssuerMetadata?
    
    private var fields: [Field]?
    
    private var refreshIssuerCache = false
    
    private var jwkSet = [JWKSet]()
    private var issuerKeys = [IssuerKey]()
    
    // MARK: - Private Methods
    
    private func checkNavigationItem() {
        if !isMovingToParent {
            let cancelBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancel))
            self.navigationItem.leftBarButtonItem = cancelBarButtonItem
        }
    }
    
    private func prepareForTable() {
        let credentialSubjectDictionary = package?.credential?.credentialSubject ?? [String: Any]()
        let schemaDictionary = package?.schema?.schema ?? [String: Any]()
        
        let allUnsortedFields = SchemaParser().getVisibleFields(for: credentialSubjectDictionary, and: schemaDictionary)
        let unsortedFilteredFields = allUnsortedFields.filter { $0.visible ?? false }
        fields = unsortedFilteredFields.sorted(by: { $0.path < $1.path })
        
        tableView.reloadData()
    }
    
    private func processCredential() {
        tableView.isUserInteractionEnabled = false
        self.activityIndicator.startAnimating()
        activityIndicator.isAccessibilityElement = true
        
        let progressString = "accessibility.indicator.loading".localized
        activityIndicator.accessibilityValue = progressString
        UIAccessibility.post(notification: .announcement, argument: progressString)
        
        self.performCredentialLogin()
            .then { _ in
                self.fetchSchema()
            }
            .then { _ in
                self.fetchIssuerMetadata()
            }
            .done { _ in
                self.updatePackage()
            }
            .catch { error in
                var title = "OrganizationDetails.organization.error.title3".localized
                var message = "OrganizationDetails.organization.error.message3".localized
                
                if (error as NSError).domain == "Login Error" {
                    title = "OrganizationDetails.organization.error.title3".localized
                    message = "OrganizationDetails.organization.error.message3".localized
                } else {
                    title = "OrganizationDetails.organization.error.title".localized
                    message = "OrganizationDetails.organization.error.message".localized
                }
                
                if let err = error as NSError? {
                    let domain = err.domain.isEmpty ? "Domain=Unknown" : "Domain=\(err.domain)"
                    let code = "Code=\(err.code)"
                    
                    message = message + String("\n\n(\(domain) | \(code))")
                }
                
                let action = [("button.title.ok".localized, IBMAlertActionStyle.cancel)]
                self.showConfirmation(title: title, message: message, actions: action) { _ in
                    self.performSegue(withIdentifier: "unwindToScan", sender: nil)
                }
            }.finally {
                self.tableView.isUserInteractionEnabled = true
                self.activityIndicator.stopAnimating()
            }
    }
    
    private func updatePackage() {
        var packageDictionary = [String: Any]()
        
        packageDictionary["credential"] = credential?.rawString
        packageDictionary["schema"] = schema?.rawString
        packageDictionary["issuerMetadata"] = issuerMetadata?.rawString
        
        package = Package(value: packageDictionary)
    }
    
    private func setSelectedOrganization() {
        tableView.isUserInteractionEnabled = false
        activityIndicator.startAnimating()
        activityIndicator.isAccessibilityElement = true
        
        let progressString = "accessibility.indicator.loading".localized
        activityIndicator.accessibilityValue = progressString
        UIAccessibility.post(notification: .announcement, argument: progressString)
        
        self.performCredentialLogin()
            .then { _ in
                self.getVerifierConfiguration()
            }
            .done { _ in }
            .catch { _ in }
            .finally {
                self.tableView.isUserInteractionEnabled = true
                self.activityIndicator.stopAnimating()
            }
    }
    
    private func discardOrganization() {
        
        showConfirmation(title: "OrganizationDetails.discard.organization.title".localized,
                         message: "OrganizationDetails.discard.organization.message".localized,
                         actions: [("wallet.discard.yes".localized, IBMAlertActionStyle.destructive), ("button.title.cancel".localized, IBMAlertActionStyle.cancel)]) { index in
            if index == 0 {
                guard let id = self.package?.credential?.id else {
                    self.performSegue(withIdentifier: "unwindToScan", sender: nil)
                    return
                }
                
                if id == DataStore.shared.currentOrganization?.credential?.id {
                    DataStore.shared.currentOrganizationDictionary = nil
                }
                
                DataStore.shared.deleteOrganization(for: id)
                
                self.performSegue(withIdentifier: "unwindToScan", sender: nil)
            }
        }
    }
}

extension OrganizationDetailsTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard package != nil else {
            self.tableView.backgroundView = tableViewPlaceholder
            return 0
        }
        
        self.tableView.backgroundView = nil
        
        return 4
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "OrganizationDetails.tableView.section.title".localized
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return fields?.count ?? 0
        } else if section == 2 {
            return 1
        } else if section == 3 {
            return 1
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrganizationBasicCellID", for: indexPath)
            
            //Title
            let titlePath = fields?.filter { $0.path == "organization" }.first
            let organizationTitle = titlePath?.value as? String ?? String()
            let organizationTitleLabel = cell.viewWithTag(2) as? UILabel
            organizationTitleLabel?.text = organizationTitle
            organizationTitleLabel?.font = AppFont.title2Scaled
            
            //Initials or Image
            var initialValue = String()
            let organizationTitleComponents = organizationTitle.components(separatedBy: " ")
            if let first = organizationTitleComponents.first {
                initialValue = String(first.prefix(1))
            }
            if (organizationTitleComponents.count > 1) {
                let second = organizationTitleComponents[1]
                initialValue = String("\(initialValue)\(String(second.prefix(1)))")
            }
            
            let initialLabel = UILabel()
            initialLabel.frame.size = CGSize(width: 100.0, height: 100.0)
            initialLabel.font = UIFont(name: AppFont.regular, size: 48)
            initialLabel.textColor = .label
            initialLabel.text = initialValue
            initialLabel.textAlignment = .center
            initialLabel.backgroundColor = .tertiarySystemBackground
            
            UIGraphicsBeginImageContext(initialLabel.frame.size)
            initialLabel.layer.render(in: UIGraphicsGetCurrentContext()!)
            let organizationImageView = cell.viewWithTag(1) as? UIImageView
            organizationImageView?.image = UIGraphicsGetImageFromCurrentImageContext()
            organizationImageView?.backgroundColor = .tertiarySystemBackground
            UIGraphicsEndImageContext()
            
            //Sub Title
            let subTitlePath = fields?.filter { $0.path == "verifierType" }.first
            let organizationSubTitleLabel = cell.viewWithTag(3) as? UILabel
            organizationSubTitleLabel?.text = subTitlePath?.value as? String
            organizationSubTitleLabel?.font = AppFont.subheadlineScaled
            
            let organizationIssuedLabel = cell.viewWithTag(4) as? UILabel
            organizationIssuedLabel?.text = nil
            if let issuanceDateString = package?.credential?.issuanceDate {
                let issuanceDate = Date.dateFromString(dateString: issuanceDateString)
                organizationIssuedLabel?.text = String(format: "result.issuedFormat".localized, Date.stringForDate(date: issuanceDate, dateFormatPattern: .IBMDefault))
            }
            organizationIssuedLabel?.font = AppFont.footnoteScaled
            
            //Expiration and Issued
            let organizationExpiresLabel = cell.viewWithTag(5) as? UILabel
            organizationExpiresLabel?.text = nil
            let credentialExpired = package?.credential?.isExpired ?? false
            if let expireDateString = package?.credential?.expirationDate {
                let expString = credentialExpired ? "result.expiredDate".localized : "result.expiresDate".localized
                let expiryDate = Date.dateFromString(dateString: expireDateString)
                organizationExpiresLabel?.text = String(format: "%@ %@", expString, Date.stringForDate(date: expiryDate, dateFormatPattern: .IBMDefault))
            }
            organizationExpiresLabel?.font = AppFont.footnoteScaled
            
            let organizationHelperLabel = cell.viewWithTag(6) as? UILabel
            organizationHelperLabel?.text = "OrganizationDetails.organization.selection.helper".localized
            
            return cell
        } else if indexPath.section == 1, let field = self.fields?[indexPath.row] {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrganizationDetailsCellID", for: indexPath)
            
            let pathArray = field.path.components(separatedBy: ".")
            if !(pathArray.isEmpty) {
                cell.textLabel?.text = pathArray.last?.snakeCased()?.capitalized
            } else {
                cell.textLabel?.text = field.path.snakeCased()?.capitalized
            }
            
            let isObfuscated = field.obfuscated ?? false
            if let value = field.value {
                cell.detailTextLabel?.text = isObfuscated ? field.getDeobfuscatedVaule(for: package?.credential) : String(describing: value)
            } else {
                cell.detailTextLabel?.text = "-"
            }
            
            cell.textLabel?.font = AppFont.subheadlineScaled
            cell.detailTextLabel?.font = AppFont.bodyScaled
            
            return cell
        } else if indexPath.section == 2, !(package?.credential?.isExpired ?? true) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrganizationBeginScanningCellID", for: indexPath)
            
            var title = "OrganizationDetails.organization.selection.button1".localized
            if let currentOrganization = DataStore.shared.currentOrganization,
               currentOrganization.credential?.id == package?.credential?.id {
                title = "OrganizationDetails.organization.selection.button2".localized
            }
            
            let selectOrganizationButton = cell.viewWithTag(1) as? UIButton
            selectOrganizationButton?.setTitle(title, for: .normal)
            selectOrganizationButton?.isAccessibilityElement = true
            selectOrganizationButton?.titleLabel?.isAccessibilityElement = true
            selectOrganizationButton?.titleLabel?.adjustsFontSizeToFitWidth = true
            
            return cell
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrganizationExpiredCellID", for: indexPath)
            return cell
        } else if indexPath.section == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrganizationDiscardScanningCellID", for: indexPath)
            
            let discardOrganizationButton = cell.viewWithTag(1) as? UIButton
            discardOrganizationButton?.isAccessibilityElement = true
            discardOrganizationButton?.titleLabel?.isAccessibilityElement = true
            discardOrganizationButton?.titleLabel?.adjustsFontSizeToFitWidth = true
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 2, !(package?.credential?.isExpired ?? true) {
            setSelectedOrganization()
        } else if indexPath.section == 3 {
            discardOrganization()
        }
    }
}

extension OrganizationDetailsTableViewController {
    
    @discardableResult
    private func performCredentialLogin() -> Promise<Void>  {
        return Promise<Void>(resolver: { resolver in
            
            guard let credential = package?.credential ?? credential else {
                DataStore.shared.resetUserLogin()
                resolver.fulfill_()
                return
            }
            
            guard let credentialString = credential.base64String,
                  credential.credentialSubject?["customerId"] != nil,
                  credential.credentialSubject?["organizationId"] != nil,
                  credential.credentialSubject?["configId"] != nil else {
                      DataStore.shared.resetUserLogin()
                      resolver.fulfill_()
                      return
                  }
            
            LoginService().performLogin(with: credentialString) { result in
                switch result {
                case let .success(json):
                    if let accessToken = json["access_token"] as? String {
                        DataStore.shared.userAccessToken = accessToken
                        DataStore.shared.loginTimeStamp = Date.stringForDate(date: Date(), locale: nil)
                        DataStore.shared.loginExpiresIn = json["expires_in"] as? Double
                        
                        resolver.fulfill_()
                        return
                    } else {
                        let error = NSError.invalidDataResponseError
                        resolver.reject(error)
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

extension OrganizationDetailsTableViewController {
    
    @discardableResult
    private func fetchSchema() -> Promise<Void> {
        return Promise<Void>(resolver: { resolver in
            guard let schemaId = credential?.credentialSchema?.id else {
                let error = NSError.requestCreateError
                resolver.reject(error)
                return
            }
            
            //Check local cache
            if let credential = credential, let schema = DataStore.shared.getSchema(for: credential) {
                self.schema = schema
                resolver.fulfill_()
                return
            }
            
            SchemaService().getSchema(schemaId: schemaId) { result in
                
                switch result {
                case let .success(data):
                    guard let payload = data["payload"] as? [String : Any], !(payload.isEmpty) else {
                        let error = NSError.invalidDataResponseError
                        resolver.reject(error)
                        return
                    }
                    
                    let schema = Schema(value: payload)
                    DataStore.shared.addNewSchema(schema: schema)
                    self.schema = schema
                    
                    resolver.fulfill_()
                    return
                    
                case let .failure(error):
                    resolver.reject(error)
                }
            }
        })
    }
    
    @discardableResult
    private func fetchIssuerMetadata() -> Promise<Void> {
        return Promise<Void>(resolver: { resolver in
            guard let issuerId = credential?.issuer else {
                resolver.fulfill_()
                return
            }
            
            //Check local cache
            if let credential = credential, let issuerMetadata = DataStore.shared.getIssuerMetadata(for: credential) {
                self.issuerMetadata = issuerMetadata
                resolver.fulfill_()
                return
            }
            
            IssuerService().getIssuerMetadata(issuerId: issuerId) { result in
                switch result {
                case let .success(data):
                    guard let payload = data["payload"] as? [String : Any], !(payload.isEmpty) else {
                        resolver.fulfill_()
                        return
                    }
                    
                    let issuerMetadata = IssuerMetadata(value: payload)
                    DataStore.shared.addNewIssuerMetadata(issuerMetadata: issuerMetadata)
                    self.issuerMetadata = issuerMetadata
                    
                    resolver.fulfill_()
                    
                case .failure(_):
                    resolver.fulfill_()
                }
            }
        })
    }
    
}

extension OrganizationDetailsTableViewController {
    
    private func getVerifierConfiguration() -> Promise<Void> {
        return Promise<Void>(resolver: { resolver in
            
            guard let currentOrganization = package,
                  let verifierCredentialInfo = currentOrganization.credential?.credentialSubject?["configId"] as? String else {
                      self.handleVerifierConfigurationError(resolver: resolver)
                      resolver.fulfill_()
                      return
                  }
            
            let verifierCredentialInfoComponents = verifierCredentialInfo.components(separatedBy: ":")
            let verifierCredentialId = verifierCredentialInfoComponents.first
            var version: String?
            
            if verifierCredentialInfoComponents.count == 2 {
                version = verifierCredentialInfoComponents.last
            }
            
            guard let id = verifierCredentialId else {
                self.handleVerifierConfigurationError(resolver: resolver)
                resolver.fulfill_()
                return
            }
            
            if let verifierConfiguration = DataStore.shared.getVerifierConfiguration(for: id), !(DataStore.shared.shouldRefreshCache(for: verifierConfiguration)) {
                DataStore.shared.addNewOrganization(organization: currentOrganization)
                DataStore.shared.currentOrganizationDictionary = currentOrganization.rawDictionary
                
                DataStore.shared.currentVerifierConfiguration = verifierConfiguration
                
                self.refreshIssuerCache = false
                
                self.handleVerifierConfigurationSuccess(resolver: resolver)
                return
            }
            
            self.refreshIssuerCache = true
            
            VerifierConfigurationServices().getVerifierConfiguration(for: id, version: version, completion: { result in
                switch result {
                case .success(let json):
                    guard let payload = json["payload"] as? [String : Any], !(payload.isEmpty) else {
                        self.handleVerifierConfigurationError(resolver: resolver)
                        resolver.fulfill_()
                        return
                    }
                    
                    guard let data = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) else {
                        self.handleVerifierConfigurationError(resolver: resolver)
                        resolver.fulfill_()
                        return
                    }
                    
                    guard var verifierConfiguration = try? VerifierConfiguration(data: data) else {
                        self.handleVerifierConfigurationError(resolver: resolver)
                        resolver.fulfill_()
                        return
                    }
                    
                    //Adding cache time before storing
                    verifierConfiguration.cachedAt = Date()
                    
                    DataStore.shared.addNewOrganization(organization: currentOrganization)
                    DataStore.shared.currentOrganizationDictionary = currentOrganization.rawDictionary
                    
                    DataStore.shared.addNewVerifierConfiguration(verifierConfiguration: verifierConfiguration)
                    DataStore.shared.currentVerifierConfiguration = verifierConfiguration
                    
                    self.handleVerifierConfigurationSuccess(resolver: resolver)
                    
                case .failure(let error):
                    self.handleVerifierConfigurationError(error, resolver: resolver)
                    resolver.fulfill_()
                    break
                }
            })
        })
    }
    
    private func handleVerifierConfigurationSuccess(resolver: Resolver<Void>) {
        self.fetchIssuerDetails()
            .then { _ in
                self.fetchSCHIssuerDetails()
            }
            .then { _ in
                self.fetchDCCIssuerDetails()
            }
            .done { _ in }
            .catch { _ in }
            .finally {
                resolver.fulfill_()
                
                self.performSegue(withIdentifier: "unwindToScan", sender: nil)
            }
    }
    
    private func handleVerifierConfigurationError(_ error: Error? = nil, resolver: Resolver<Void>) {
        DataStore.shared.currentVerifierConfiguration = nil
        
        let title = "OrganizationDetails.organization.error.title3".localized
        var message = "OrganizationDetails.organization.error.message3".localized
        
        if let err = error as NSError? {
            let domain = err.domain.isEmpty ? "Domain=Unknown" : "Domain=\(err.domain)"
            let code = "Code=\(err.code)"
            
            message = message + String("\n\n(\(domain) | \(code))")
        }
        
        let action = [("button.title.cancel".localized, IBMAlertActionStyle.cancel),
                      ("OrganizationDetails.discard.organization.title".localized, IBMAlertActionStyle.destructive)]
        
        self.showConfirmation(title: title, message: message, actions: action) { index in
            if index == 1 {
                self.discardOrganization()
            }
        }
        
        resolver.fulfill_()
    }
    
}

extension OrganizationDetailsTableViewController {
    
    private func fetchIssuerDetails() -> Promise<Void> {
        return Promise<Void>(resolver: { resolver in
            
            guard self.refreshIssuerCache || (DataStore.shared.allIssuer?.isEmpty ?? true) else {
                resolver.fulfill_()
                return
            }
            
            IssuerService().getIssuer() { result in
                switch result {
                case .success(let json):
                    guard let payload = json["payload"] as? [[String: Any]] else {
                        resolver.fulfill_()
                        return
                    }
                    
                    let issuers = payload.compactMap({ Issuer(value: $0) })
                    DataStore.shared.overwriteIssuers(issuers: issuers)
                    
                    resolver.fulfill_()
                    
                case .failure:
                    resolver.fulfill_()
                }
            }
            
        })
    }
    
    private func fetchSCHIssuerDetails() -> Promise<Void> {
        return Promise<Void>(resolver: { resolver in
            
            guard self.refreshIssuerCache || (DataStore.shared.allJWKSet?.isEmpty ?? true) else {
                resolver.fulfill_()
                return
            }
            
            self.jwkSet = [JWKSet]()
            
            self.fetchSHCIssuerDetails(bookmark: nil, resolver: resolver)
        })
    }
    
    private func fetchSHCIssuerDetails(bookmark: String?, resolver: Resolver<Void>) {
        
        IssuerService().getGenericIssuer(bookmark: bookmark, pagesize: IssuerService.max_page_size, type: .SHC) { result in
            switch result {
            case .success(let json):
                guard let jsonPayload = json["payload"] as? [String : Any],
                      let payload = jsonPayload["payload"] as? [[String : Any]], !(payload.isEmpty) else {
                          self.updateJWKSet()
                          resolver.fulfill_()
                          return
                      }
                
                guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                      let jwkSet = try? JSONDecoder().decode([JWKSet].self, from: data) else {
                          self.updateJWKSet()
                          resolver.fulfill_()
                          return
                      }
                
                self.jwkSet.append(contentsOf: jwkSet)
                
                if let bookmark = jsonPayload["bookmark"] as? String {
                    self.fetchSHCIssuerDetails(bookmark: bookmark, resolver: resolver)
                } else {
                    self.updateJWKSet()
                    resolver.fulfill_()
                }
                
            case .failure:
                resolver.fulfill_()
            }
        }
        
    }
    
    private func updateJWKSet() {
        if !(jwkSet.isEmpty) {
            DataStore.shared.overwriteJWKSet(jwkSet: self.jwkSet)
        }
    }
    
    private func fetchDCCIssuerDetails() -> Promise<Void> {
        return Promise<Void>(resolver: { resolver in
            
            guard self.refreshIssuerCache || (DataStore.shared.allIssuerKey?.isEmpty ?? true) else {
                resolver.fulfill_()
                return
            }
            
            self.issuerKeys = [IssuerKey]()
            
            self.fetchDCCIssuerDetails(bookmark: nil, resolver: resolver)
        })
    }
    
    private func fetchDCCIssuerDetails(bookmark: String?, resolver: Resolver<Void>) {
        
        IssuerService().getGenericIssuer(bookmark: bookmark, pagesize: IssuerService.max_page_size, type: .DCC) { result in
            switch result {
            case .success(let json):
                guard let jsonPayload = json["payload"] as? [String : Any],
                      let payload = jsonPayload["payload"] as? [[String : Any]], !(payload.isEmpty) else {
                          self.updateIssuerKeys()
                          resolver.fulfill_()
                          return
                      }
                
                guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                      let issuerKeys = try? JSONDecoder().decode([IssuerKey].self, from: data) else {
                          self.updateIssuerKeys()
                          resolver.fulfill_()
                          return
                      }
                
                self.issuerKeys.append(contentsOf: issuerKeys)
                
                if let bookmark = jsonPayload["bookmark"] as? String {
                    self.fetchDCCIssuerDetails(bookmark: bookmark, resolver: resolver)
                } else {
                    self.updateIssuerKeys()
                    resolver.fulfill_()
                }
            case .failure:
                resolver.fulfill_()
            }
        }
        
    }
    
    private func updateIssuerKeys() {
        if !(self.issuerKeys.isEmpty) {
            DataStore.shared.overwriteIssuerKeys(issuerKeys: self.issuerKeys)
        }
    }
    
}
