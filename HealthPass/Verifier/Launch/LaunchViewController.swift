//
//  LaunchViewController.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import PromiseKit
import VerificationEngine

class LaunchViewController: UIViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.font = AppFont.title1Scaled
        versionLabel.font = AppFont.bodyScaled
//        copyrightLabel.font = AppFont.bodyScaled
        privacyPolicyButton.titleLabel?.font = AppFont.bodyScaled
        
        versionLabel?.text = String(format: "Version %@", Bundle.main.appVersionNumber ?? "")
        
        if jailbreakDetection() {
            return
        }
        
        organizationLogoImageView.isAccessibilityElement = true
        organizationLogoImageView.accessibilityTraits = .image
        organizationLogoImageView.accessibilityLabel = "accessibility.organization.logo".localized
        
        activityIndicatorView?.layer.borderColor = UIColor.systemBlue.cgColor
        activityIndicatorView?.layer.shadowColor = UIColor.black.cgColor
        activityIndicatorView?.isAccessibilityElement = true
        
        let progressString = "accessibility.indicator.loading".localized
        activityIndicatorView?.accessibilityValue = progressString
        UIAccessibility.post(notification: .announcement, argument: progressString)
        
        continueButton.isHidden = !(DataStore.shared.didAgreeTermsConditions && DataStore.shared.didAcceptPrivacy && DataStore.shared.didSelectDataCenter)
        continueImageView.isHidden = !(DataStore.shared.didAgreeTermsConditions && DataStore.shared.didAcceptPrivacy && DataStore.shared.didSelectDataCenter)
        
        determineFlow()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var copyrightLabel: UILabel!
    @IBOutlet weak var privacyPolicyButton: UIButton!
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var continueImageView: UIImageView!
    @IBOutlet weak var organizationLogoImageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIView?
    
    // MARK: - IBAction
    
    @IBAction func unwindToLaunch(segue: UIStoryboardSegue) {
        if segue.source is TermsConditionsViewController, !(DataStore.shared.didAgreeTermsConditions) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.view.isUserInteractionEnabled = true
                self.activityIndicatorView?.isHidden = true
                
                self.continueButton.isHidden = false
                self.continueImageView.isHidden = false
            }
            return
        } else {
            continueButton.isHidden = !(DataStore.shared.didAgreeTermsConditions && DataStore.shared.didAcceptPrivacy && DataStore.shared.didSelectDataCenter)
            self.continueImageView.isHidden = !(DataStore.shared.didAgreeTermsConditions && DataStore.shared.didAcceptPrivacy && DataStore.shared.didSelectDataCenter)
            
            determineFlow()
        }
    }
    
    @IBAction func onPrivacyPolicy(_ sender: UIButton) {
        self.performSegue(withIdentifier: self.showPrivacyPolicy, sender: nil)
    }
    
    @IBAction func onContinue(_ sender: UIButton) {
        if !(DataStore.shared.didAgreeTermsConditions)
            || !(DataStore.shared.didAcceptPrivacy)
            || !(DataStore.shared.didSelectDataCenter) {
            determineFlow()
            return
        }
        
        view.isUserInteractionEnabled = false
        activityIndicatorView?.isHidden = false
        
        self.performCredentialLogin()
            .then { _ in
                self.submitMetrics()
            }
            .then { _ in
                self.getVerifierConfiguration()
            }
            .then { _ in
                self.fetchIssuerDetails()
            }
            .then { _ in
                self.fetchSCHIssuerDetails()
            }
            .then { _ in
                self.fetchDCCIssuerDetails()
            }
            .done { _ in }
            .catch { _ in }
            .finally {
                self.view.isUserInteractionEnabled = true
                self.activityIndicatorView?.isHidden = true
                
                self.performSegue(withIdentifier: self.showBaseSegue, sender: nil)
            }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private let showBaseSegue = "showBase"
    private let showPrivacyPolicy = "showPrivacyPolicy"
    private let showLoginSegue = "showLogin"
    private let showTermsConditions = "showTermsConditions"
    private let showSelectDataCenter = "showSelectDataCenter"
    private let showGetStarted = "showGetStarted"
    
    private var refreshIssuerCache = false
    
    private var jwkSet = [JWKSet]()
    private var issuerKeys = [IssuerKey]()
    
    // MARK: - Private Methods
    
    private func determineFlow() {
        view.isUserInteractionEnabled = true
        activityIndicatorView?.isHidden = true
        
        let progressString = "accessibility.indicator.loading".localized
        activityIndicatorView?.accessibilityValue = progressString
        UIAccessibility.post(notification: .announcement, argument: progressString)
        
        if !(DataStore.shared.didAgreeTermsConditions) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.performSegue(withIdentifier: self.showTermsConditions, sender: nil)
            }
        } else if !(DataStore.shared.didAcceptPrivacy) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.performSegue(withIdentifier: self.showPrivacyPolicy, sender: nil)
            }
        } else if !(DataStore.shared.didSelectDataCenter) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.performSegue(withIdentifier: self.showSelectDataCenter, sender: nil)
            }
        } else if !(DataStore.shared.didGetStarted) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.performSegue(withIdentifier: self.showGetStarted, sender: nil)
            }
        }
    }
    
    private func performCredentialLogin() -> Promise<Void>  {
        return Promise<Void>(resolver: { resolver in
            guard let credentialString = DataStore.shared.currentOrganization?.credential?.base64String else {
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
                        resolver.fulfill_()
                        return
                    }
                    
                case .failure:
                    resolver.fulfill_()
                    return
                }
                
            }
        })
    }
    
    private func getVerifierConfiguration() -> Promise<Void> {
        return Promise<Void>(resolver: { resolver in
            
            guard let currentOrganization = DataStore.shared.currentOrganization,
                  let verifierCredentialInfo = currentOrganization.credential?.credentialSubject?["configId"] as? String else {
                      self.handleVerifierConfigurationError()
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
                self.handleVerifierConfigurationError()
                resolver.fulfill_()
                return
            }
            
            if let verifierConfiguration = DataStore.shared.getVerifierConfiguration(for: id), !(DataStore.shared.shouldRefreshCache(for: verifierConfiguration)) {
                DataStore.shared.currentOrganizationDictionary = currentOrganization.rawDictionary
                DataStore.shared.currentVerifierConfiguration = verifierConfiguration
                
                self.refreshIssuerCache = false
                
                resolver.fulfill_()
                return
            }
            
            self.refreshIssuerCache = true
            
            VerifierConfigurationServices().getVerifierConfiguration(for: id, version: version, completion: { result in
                switch result {
                case .success(let json):
                    guard let payload = json["payload"] as? [String : Any], !(payload.isEmpty) else {
                        self.handleVerifierConfigurationError()
                        resolver.fulfill_()
                        return
                    }
                    
                    guard let data = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) else {
                        self.handleVerifierConfigurationError()
                        resolver.fulfill_()
                        return
                    }
                    
                    guard var verifierConfiguration = try? VerifierConfiguration(data: data) else {
                        self.handleVerifierConfigurationError()
                        resolver.fulfill_()
                        return
                    }
                    
                    //Adding cache time before storing
                    verifierConfiguration.cachedAt = Date()
                    
                    DataStore.shared.currentOrganizationDictionary = currentOrganization.rawDictionary
                    
                    DataStore.shared.addNewVerifierConfiguration(verifierConfiguration: verifierConfiguration)
                    DataStore.shared.currentVerifierConfiguration = verifierConfiguration
                    
                    resolver.fulfill_()
                    break
                    
                case .failure(let error):
                    self.handleVerifierConfigurationError(error)
                    resolver.fulfill_()
                    break
                }
            })
        })
    }
    
    private func handleVerifierConfigurationError(_ error: Error? = nil) {
        DataStore.shared.currentVerifierConfiguration = nil
        DataStore.shared.currentOrganizationDictionary = nil
    }
    
    private func submitMetrics() -> Promise<Void> {
        return Promise<Void>(resolver: { resolver in
            guard let aggregatedDictionary = DataStore.shared.getAggregatedMetricsDictionary() else {
                resolver.fulfill_()
                return
            }
            
            MetricsService().submitMetrics(data: aggregatedDictionary, completion: { result in
                switch result {
                case .success:
                    DataStore.shared.deleteAllMetrics()
                    
                case .failure:
                    //Check if Metrics goes over 1000 count with submit success - Apr 30 release, v1.0.2
                    if let allMetricsDictionary = DataStore.shared.allMetricsDictionary,
                       allMetricsDictionary.count >= MetricsUploadCount.thousand.rawValue {
                        DataStore.shared.deleteAllMetrics()
                    }
                    
                    break
                }
                
                resolver.fulfill_()
            })
        })
    }
    
    @discardableResult
    private func jailbreakDetection() -> Bool {
        if (SceneDelegate.jailbroken(application: UIApplication.shared)) {
            DispatchQueue.main.async {
                self.showConfirmation(title: "launch.jailbreak.title".localized,
                                      message: "launch.jailbreak.message".localized,
                                      actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)]) { _ in
                    exit(0)
                }
            }
            
            return true
        }
        
        return false
    }
}


extension LaunchViewController {
    
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
