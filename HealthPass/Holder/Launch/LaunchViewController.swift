//
//  LaunchViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class LaunchViewController: UIViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.font = AppFont.title1Scaled
        versionLabel.font = AppFont.bodyScaled
        copyrightLabel.font = AppFont.bodyScaled
        privacyPolicyButton.titleLabel?.font = AppFont.bodyScaled
        
        versionLabel?.text = String(format: "Version %@", Bundle.main.appVersionNumber ?? "")
        
        if jailbreakDetection() {
            return
        }
        
        continueButton.isHidden = true
        continueImageView.isHidden = true
        
        activityIndicatorView?.layer.borderColor = UIColor.systemBlue.cgColor
        activityIndicatorView?.layer.shadowColor = UIColor.black.cgColor
        activityIndicatorView?.isAccessibilityElement = true
        
        let progressString = "accessibility.indicator.loading".localized
        activityIndicatorView?.accessibilityValue = progressString
        UIAccessibility.post(notification: .announcement, argument: progressString)
        
        view.isUserInteractionEnabled = false
        activityIndicatorView?.isHidden = false
        
        self.determineFlow()
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
    @IBOutlet weak var activityIndicatorView: UIView?
    
    // MARK: - IBAction
    
    @IBAction func unwindToLaunch(segue: UIStoryboardSegue) {
        if let pinOptionsViewController = segue.source as? PinOptionsViewController, pinOptionsViewController.isPINUnlockSuccessful {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.performSegue(withIdentifier: self.showBaseSegue, sender: nil)
            }
            return
        } else if segue.source is TermsConditionsViewController, !(DataStore.shared.didAgreeTermsConditions) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.view.isUserInteractionEnabled = true
                self.activityIndicatorView?.isHidden = true
                
                self.continueButton.isHidden = false
                self.continueImageView.isHidden = false
            }
            return
        }
        
        determineFlow()
    }
    
    @IBAction func showPrivacyPolicy(_ sender: UIButton) {
        self.performSegue(withIdentifier: self.showPrivacyPolicy, sender: nil)
    }
    
    @IBAction func onContinue(_ sender: UIButton) {
        if !(DataStore.shared.didAgreeTermsConditions)
            || !(DataStore.shared.didAcceptPrivacy)
            || !(DataStore.shared.didSelectDataCenter)
            || !(DataStore.shared.didGetStarted) {
            determineFlow()
        } else {
            self.continueFlow()
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showPinOptions,
           let navigationController = segue.destination as? CustomNavigationController,
           let pinOptionsViewController = navigationController.viewControllers.first as? PinOptionsViewController {
            pinOptionsViewController.mode = (DataStore.shared.hasPINEnabled) ? .unlock : .create
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let showLoginSegue = "showLogin"
    private let showBaseSegue = "showBase"
    private let showPrivacyPolicy = "showPrivacyPolicy"
    private let showTermsConditions = "showTermsConditions"
    private let showSelectDataCenter = "showSelectDataCenter"
    private let showGetStarted = "showGetStarted"
    private let showPinOptions = "showPinOptions"
    
    private var refreshIssuerCache = false
    // MARK: Private Methods
    
    private func determineFlow() {
        view.isUserInteractionEnabled = false
        activityIndicatorView?.isHidden = false
        
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
        } else {
            self.view.isUserInteractionEnabled = true
            self.activityIndicatorView?.isHidden = true
            self.continueButton.isHidden = false
            self.continueImageView.isHidden = false
        }
    }
    
    private func continueFlow() {
        view.isUserInteractionEnabled = false
        activityIndicatorView?.isHidden = false
        
        if !(DataStore.shared.didFinishPinSetup) || (DataStore.shared.hasPINEnabled) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.performSegue(withIdentifier: self.showPinOptions, sender: nil)
            }
        } else {
            view.isUserInteractionEnabled = true
            activityIndicatorView?.isHidden = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.performSegue(withIdentifier: self.showBaseSegue, sender: nil)
            }
        }
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
