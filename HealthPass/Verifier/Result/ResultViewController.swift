//
//  ResultViewController.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import VerificationEngine
import VerifiableCredential
import PromiseKit
import OSLog
import SwiftCBOR
import jsonlogic

extension OSLog {
    static let resultViewControllerOSLog = OSLog(subsystem: subsystem, category: "ResultViewController")
}

extension VerifierConfiguration {
    
    var isLegacyConfiguration: Bool {
        guard let _ = self.specificationConfigurations else {
            return true
        }
        
        return false
    }
    
}

class ResultViewController: UIViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = nil
        
        self.doneBarButtonItem?.isEnabled = false
        self.infoBarButtonItem?.isEnabled = false
        self.dismissButton?.isHidden = true
        
        self.resultImage = loadingImage
        self.resultTintColor = .systemGray4
        self.resultTitle = "result.Verifying".localized
        
        UIView.performWithoutAnimation {
            self.resultTableView?.reloadData()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if testMode {
            self.navigationItem.title = "TEST MODE"
        }
        
        self.performVerification(for: verifiableObject)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? CustomNavigationController,
           let resultDetailsTableViewController = navigationController.viewControllers.first as? ResultDetailsTableViewController {
            resultDetailsTableViewController.successfulRules = self.successfulRules
            resultDetailsTableViewController.failedRules = self.failedRules
        }
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem?
    @IBOutlet weak var infoBarButtonItem: UIBarButtonItem?
    
    @IBOutlet weak var resultTableView: UITableView?
    @IBOutlet weak var dismissButton: UIButton?
    
    // MARK: - IBAction
    
    @IBAction func onDone(_ sender: Any) {
        if self.testMode {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.performSegue(withIdentifier: "unwindToScan", sender: nil)
        }
    }
    
    @IBAction func onInfo(_ sender: Any) {
        var message = "verification.successful".localized
        if let error = self.verificationError {
            message = error.localizedDescription
        }
        
        var moreDetails = false
        if let successfulRules = successfulRules, !(successfulRules.isEmpty) {
            message = message + String("\n [Successful Rules = \(successfulRules.count)]")
            moreDetails = true
        }
        
        if let failedRules = failedRules, !(failedRules.isEmpty) {
            message = message + String("\n [Failed Rules = \(failedRules.count)]")
            moreDetails = true
        }
        
        if moreDetails {
            showConfirmation(title: String("\(metricsStatus.rawValue)"),
                             message: message,
                             actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel), ("More Info".localized, IBMAlertActionStyle.default)]) { index in
                if index == 1 {
                    self.performSegue(withIdentifier: self.showResultDetails, sender: nil)
                }
            }
            
        } else {
            showConfirmation(title: String("\(metricsStatus.rawValue)"),
                             message: message,
                             actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
        }
    }
    
    @IBAction func onDismiss(_ sender: Any) {
        guard dismissTimer != nil else {
            if self.testMode {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.performSegue(withIdentifier: "unwindToScan", sender: nil)
            }
            return
        }
        
        self.dismissTimer?.invalidate()
        self.dismissTimer = nil
        
        self.dismissButton?.backgroundColor = .link
        self.dismissButton?.setImage(UIImage(systemName: "qrcode.viewfinder"), for: .normal)
        self.dismissButton?.setTitle(String("Scan Next Pass"), for: .normal)
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    internal var testMode: Bool = false {
        didSet {
            if testMode {
                self.navigationItem.title = "TEST MODE"
            }
        }
    }
    
    internal var verifiableObject: VerifiableObject? {
        didSet {
            self.type = verifiableObject?.type ?? .unknown
        }
    }
    
    internal var type: VCType = .unknown
    
    internal var verifyEngine: VerifyEngine!
    
    internal var metricsStatus: Metric.MetricsStatus = .unknown
    
    internal var resultImage: UIImage? = UIImage(systemName: "clock")
    internal var resultTitle: String? = "result.Verifying".localized
    internal var resultTintColor: UIColor? = .systemGray2
    
    internal let loadingImage = UIImage(systemName: "clock.fill")
    internal let successImage = UIImage(systemName: "checkmark.circle.fill")
    internal let failImage = UIImage(systemName: "multiply.circle.fill")
    
    internal var specificationConfiguration: SpecificationConfiguration?

    internal var displayFields = [DisplayField]() {
        didSet {
            self.resultTableView?.reloadData()
        }
    }
    
    internal var issuerMetadata: IssuerMetadata?
    
    internal var fetchingIssuerDetails: Bool = true
    
    internal var issuerDetails: String? {
        didSet {
            UIView.performWithoutAnimation {
                self.resultTableView?.reloadData()
            }
        }
    }
    
    internal var successfulRules: [Rule]?
    internal var failedRules: [Rule]?
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    private var verificationError: Error?
    
    private var dismissTimer: Timer?
    
    private var dismissTimeInterval = TimeInterval(5)
    
    private var showResultDetails = "showResultDetails"
    
    // MARK: Private Methods
    
    private func performVerification(for verifiableObject: VerifiableObject?) {
        guard let verifiableObject = self.verifiableObject else { return }
       
        guard let currentVerifierConfiguration = DataStore.shared.currentVerifierConfiguration else { return }

        self.verifyEngine = VerifyEngine(verifiableObject: verifiableObject)
        
        self.doneBarButtonItem?.isEnabled = false
        self.infoBarButtonItem?.isEnabled = false
        self.dismissButton?.isHidden = true
        
        self.resultImage = loadingImage
        self.resultTintColor = .systemGray4
        self.resultTitle = "result.Verifying".localized
        
        UIView.performWithoutAnimation {
            self.resultTableView?.reloadData()
        }
        
        if currentVerifierConfiguration.isLegacyConfiguration {
            self.performLegacyVerification()
        } else {
            self.performVerification()
        }
    }
    
    private func performLegacyVerification() {
        self.isKnown()
            .ensure {
                os_log("Ensure - isKnown ", log: OSLog.resultViewControllerOSLog, type: .info)
            }
            .then { _ in
                self.isTrusted()
            }
            .ensure {
                os_log("Ensure - isTrusted ", log: OSLog.resultViewControllerOSLog, type: .info)
            }
            .then { _ in
                self.isNotRevoked()
            }
            .ensure {
                os_log("Ensure - isNotRevoked", log: OSLog.resultViewControllerOSLog, type: .info)
            }
            .then { _ in
                self.isValidSignature()
            }
            .ensure {
                os_log("Ensure - isValidSignature ", log: OSLog.resultViewControllerOSLog, type: .info)
            }
            .then { _ in
                self.doesMatchRules()
            }
            .ensure {
                os_log("Ensure - doesMatchRules ", log: OSLog.resultViewControllerOSLog, type: .info)
            }
            .done { _ in
                os_log("Done - performVerification ", log: OSLog.resultViewControllerOSLog, type: .info)
                
                self.verificationError = nil
                
                self.metricsStatus = .Verified
                
                self.prepareDisplayFields()
                
                self.fetchingIssuerDetails = true
                self.fetchIssuerDetails { self.fetchingIssuerDetails = false }
                
                self.resultImage = self.successImage
                self.resultTintColor = .systemGreen
                self.resultTitle = "result.Verified".localized
                
                UIView.performWithoutAnimation {
                    self.resultTableView?.reloadData()
                }
            }
            .catch { error in
                os_log("Catch - performVerification - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, error.localizedDescription)
                
                self.verificationError = error
                
                self.metricsStatus = .Unverified
                
                self.resultImage = self.failImage
                self.resultTintColor = .systemRed
                self.resultTitle = "result.notVerified".localized
                
                UIView.performWithoutAnimation {
                    self.resultTableView?.reloadData()
                }
            }
            .finally {
                os_log("Finally - performVerification ", log: OSLog.resultViewControllerOSLog, type: .info)
                
                if !(self.testMode) {
                    self.createMetrics()
                    self.submitMetrics()
                }
                
                self.doneBarButtonItem?.isEnabled = true
                self.infoBarButtonItem?.isEnabled = true
                self.dismissButton?.isHidden = false
                
                self.checkAutoDismiss()
                self.generateFeedback()
            }
    }
    
    private func performVerification() {
        guard let verifierConfiguration = DataStore.shared.currentVerifierConfiguration else { return }
        
        self.isKnown(with: verifierConfiguration)
            .ensure {
                os_log("Ensure - isKnown ", log: OSLog.resultViewControllerOSLog, type: .info)
            }
            .then { specificationConfiguration in
                self.isTrusted(with: specificationConfiguration)
            }
            .ensure {
                os_log("Ensure - isTrusted ", log: OSLog.resultViewControllerOSLog, type: .info)
            }
            .then { specificationConfiguration in
                self.isNotRevoked(with: specificationConfiguration)
            }
            .ensure {
                os_log("Ensure - isNotRevoked", log: OSLog.resultViewControllerOSLog, type: .info)
            }
            .then { specificationConfiguration in
                self.isValidSignature(with: specificationConfiguration)
            }
            .ensure {
                os_log("Ensure - isValidSignature ", log: OSLog.resultViewControllerOSLog, type: .info)
            }
            .then { specificationConfiguration in
                self.doesMatchRules(with: specificationConfiguration)
            }
            .ensure {
                os_log("Ensure - doesMatchRules ", log: OSLog.resultViewControllerOSLog, type: .info)
            }
            .done { specificationConfiguration in
                os_log("Done - performVerification ", log: OSLog.resultViewControllerOSLog, type: .info)
                
                self.specificationConfiguration = specificationConfiguration
                
                self.verificationError = nil
                
                self.metricsStatus = .Verified
                
                self.prepareDisplayFields(for: specificationConfiguration)
                
                self.fetchingIssuerDetails = true
                self.fetchIssuerDetails { self.fetchingIssuerDetails = false }
                
                self.resultImage = self.successImage
                self.resultTintColor = .systemGreen
                self.resultTitle = "result.Verified".localized
                
                UIView.performWithoutAnimation {
                    self.resultTableView?.reloadData()
                }
            }
            .catch { error in
                os_log("Catch - performVerification - %{public}@", log: OSLog.resultViewControllerOSLog, type: .error, error.localizedDescription)
                
                self.verificationError = error
                
                self.metricsStatus = .Unverified
                
                self.resultImage = self.failImage
                self.resultTintColor = .systemRed
                self.resultTitle = "result.notVerified".localized
                
                UIView.performWithoutAnimation {
                    self.resultTableView?.reloadData()
                }
            }
            .finally {
                os_log("Finally - performVerification ", log: OSLog.resultViewControllerOSLog, type: .info)
                
                if !(self.testMode) {
                    self.createMetrics(with: self.specificationConfiguration)
                    self.submitMetrics()
                }
                
                self.doneBarButtonItem?.isEnabled = true
                self.infoBarButtonItem?.isEnabled = true
                self.dismissButton?.isHidden = false
                
                self.checkAutoDismiss()
                self.generateFeedback()
            }

    }
    
    private func checkAutoDismiss() {
        guard DataStore.shared.kioskModeState else {
            return
        }
        
        if !(DataStore.shared.alwaysDismissState) && (self.metricsStatus == .Unverified) {
            return
        }
        
        self.dismissTimeInterval = TimeInterval(DataStore.shared.alwaysDismissDuration)
        
        self.dismissButton?.backgroundColor = .systemRed
        self.dismissButton?.setImage(nil, for: .normal)
        self.dismissButton?.setTitle(String("Closing in \(Int(dismissTimeInterval)) seconds..."), for: .normal)
        
        self.dismissTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    
    @objc private func updateCounter() {
        if self.dismissTimeInterval > 0 {
            self.dismissButton?.setTitle(String("Closing in \(Int(dismissTimeInterval)) seconds..."), for: .normal)
            self.dismissTimeInterval -= 1
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                if self.testMode {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.performSegue(withIdentifier: "unwindToScan", sender: nil)
                }
            }
            
            self.dismissTimer = nil
        }
    }
    
    private func generateFeedback() {
        if DataStore.shared.soundFeedbackState {
            switch self.metricsStatus {
            case .unknown: self.generateSoundFeedback(.warning)
            case .Verified: self.generateSoundFeedback(.success)
            case .Unverified: self.generateSoundFeedback(.error)
            }
        }
        
        if DataStore.shared.hapticFeedbackState {
            switch self.metricsStatus {
            case .unknown: self.generateNotificationFeedback(.warning)
            case .Verified: self.generateNotificationFeedback(.success)
            case .Unverified: self.generateNotificationFeedback(.error)
            }
        }
    }
    
}

extension ResultViewController {
    
    func getValue(at path: String, for json: [String: Any]) -> String? {
        var path = path.replacingOccurrences(of: "[", with: ".", options: .literal, range: nil)
        path = path.replacingOccurrences(of: "]", with: "", options: .literal, range: nil)
        
        let keys = path.components(separatedBy: ".")
        var trimmedValue: Any? = json
        
        var value: String?
        keys.forEach { key in
            
            if let index = Int(key) {
                guard let loopingValue = trimmedValue as? [Any], !(loopingValue.isEmpty), loopingValue.count > index else {
                    return
                }
                
                if keys.last == key {
                    let val = loopingValue[index]
                    if let directValue = val as? String {
                        value = directValue
                    } else if let arrayValue = val as? [Any] {
                        let stringArrayValue = arrayValue.compactMap{ String(describing: $0) }
                        value = stringArrayValue.joined(separator: " ")
                    } else if let dictionaryValue = val as? [String: Any], let data = try? JSONSerialization.data(withJSONObject: dictionaryValue, options: [.sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]) as Data {
                        value = String(data: data, encoding: .utf8)
                    } else {
                        value = String(describing: val)
                    }
                }
                
                trimmedValue = loopingValue[index]
            } else {
                guard let loopingValue = trimmedValue as? [String: Any], !(loopingValue.isEmpty) else {
                    return
                }
                
                if keys.last == key, let val = loopingValue[key] {
                    if let directValue = val as? String {
                        value = directValue
                    } else if let arrayValue = val as? [Any] {
                        let stringArrayValue = arrayValue.compactMap{ String(describing: $0) }
                        value = stringArrayValue.joined(separator: " ")
                    } else if let dictionaryValue = val as? [String: Any], let data = try? JSONSerialization.data(withJSONObject: dictionaryValue, options: [.sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]) as Data {
                        value = String(data: data, encoding: .utf8)
                    } else {
                        value = String(describing: val)
                    }
                }
                
                trimmedValue = loopingValue[key]
            }
        }
        
        return value
    }
    
    func getValue(at path: String, for map: [CBOR: CBOR]) -> String? {
        var path = path.replacingOccurrences(of: "[", with: ".", options: .literal, range: nil)
        path = path.replacingOccurrences(of: "]", with: "", options: .literal, range: nil)
        
        let keys = path.components(separatedBy: ".")
        var trimmedValue: Any? = map
        
        var value: String?
        keys.forEach { key in
            
            if let index = Int(key) {
                guard let loopingValue = trimmedValue as? [CBOR], !(loopingValue.isEmpty), loopingValue.count > index else {
                    return
                }
                
                if keys.last == key {
                    value = loopingValue[index].asString()
                }
                
                let movingJson = loopingValue[index]
                trimmedValue = movingJson.asMap() ?? movingJson.asList() ?? movingJson
            } else {
                guard let loopingValue = trimmedValue as? [CBOR: CBOR], !(loopingValue.isEmpty) else {
                    return
                }
                
                if keys.last == key {
                    value = loopingValue[CBOR(stringLiteral: key)]?.asString()
                }
                
                trimmedValue = loopingValue[CBOR(stringLiteral: key)]?.asMap() ?? loopingValue[CBOR(stringLiteral: key)]?.asList() ?? loopingValue[CBOR(stringLiteral: key)]
            }
        }
        
        return value
    }
}
