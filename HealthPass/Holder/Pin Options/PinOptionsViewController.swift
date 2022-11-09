//
//  PinSetupViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import LocalAuthentication

enum PinOptions {
    case create
    case confirm
    case unlock
    
    var title: String {
        switch self {
        case .create: return "pin.title.create".localized
        case .confirm: return "pin.title.confirm".localized
        case .unlock: return "pin.title.unlock".localized
        }
    }
    
    var detail: String {
        switch self {
        case .create: return "pin.detail.create".localized
        case .confirm: return "pin.detail.confirm".localized
        case .unlock: return "pin.detail.unlock".localized
        }
    }
}


class PinOptionsViewController: UIViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        detailLabel?.font = AppFont.bodyScaled
        
        isModalInPresentation = true
        
        navigationItem.rightBarButtonItems = nil
        navigationItem.leftBarButtonItems = nil
        
        setupView()
        updateImageView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let isBiometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        if isBiometricAvailable && (context.biometryType == .touchID || context.biometryType == .faceID) {
            biometricLogin()
        }
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var detailLabel: UILabel?
    
    @IBOutlet weak var pin1ImageView: UIImageView?
    @IBOutlet weak var pin2ImageView: UIImageView?
    @IBOutlet weak var pin3ImageView: UIImageView?
    @IBOutlet weak var pin4ImageView: UIImageView?
    
    @IBOutlet weak var biometricButton: UIButton!
    
    // MARK: - IBAction
    
    @IBAction func onNumber(_ sender: UIButton) {
        generateImpactFeedback()
        
        if mode == .create {
            createPinDictionary[index] = sender.tag
        } else if mode == .confirm {
            confirmPinDictionary[index] = sender.tag
        } else if mode == .unlock {
            unlockPinDictionary[index] = sender.tag
        }
        
        index += 1
        updateImageView()
        validatePin()
    }
    
    @IBAction func onBackspace(_ sender: UIButton) {
        generateImpactFeedback(style: .medium)
        
        if mode == .create {
            createPinDictionary[index] = nil
        } else if mode == .confirm {
            confirmPinDictionary[index] = nil
        } else if mode == .unlock {
            unlockPinDictionary[index] = nil
        }
        
        index -= 1
        if index < 0 { index = 0 }
        
        updateImageView()
        validatePin()
    }
    
    @IBAction func onBiometric(_ sender: UIButton) {
        biometricLogin()
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    var isPINUnlockSuccessful: Bool = false
    
    var isSettingsScene: Bool = false
    
    var mode: PinOptions = .create {
        didSet {
            setupView()
            updateImageView()
        }
    }
    
    // MARK: Internal Methods
    
    @objc
    func finishPINSetup() {
        DataStore.shared.didFinishPinSetup = true
        performSegue(withIdentifier: isSettingsScene ? "unwindToPasscode" : "unwindToLaunch", sender: nil)
    }
    
    @objc
    func resetWallet() {
        mode = .unlock
        
        showConfirmation(title: "pin.reset.title".localized, message: "pin.reset.message".localized,
                         actions: [("profile.reset.action".localized, IBMAlertActionStyle.destructive), ("button.title.cancel".localized, IBMAlertActionStyle.cancel)], completion: { index in
            if index == 0 {
                DataStore.shared.resetKeychain(with: { _ in
                    self.performSegue(withIdentifier: "unwindToLaunch", sender: nil)
                })
            }
        })
    }
    
    @objc
    func cancelPINSetup() {
        performSegue(withIdentifier: "unwindToPasscode", sender: nil)
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let context = LAContext()
    
    private var index: Int = 0
    
    private var createPinDictionary = [Int: Int?]()
    private var confirmPinDictionary = [Int: Int?]()
    private var unlockPinDictionary = [Int: Int?]()
    
    private var skipBarButton: UIBarButtonItem {
        return UIBarButtonItem(title: "pin.skip.title".localized, style: .plain, target: self, action: #selector(finishPINSetup))
    }
    
    private var resetWalletBarButton: UIBarButtonItem {
        let resetWalletBarButton = UIBarButtonItem(title: "pin.reset.title".localized, style: .plain, target: self, action: #selector(resetWallet))
        resetWalletBarButton.tintColor = .systemRed
        return resetWalletBarButton
    }
    
    private var cancelBarButton: UIBarButtonItem {
        return UIBarButtonItem(title: "button.title.cancel".localized, style: .plain, target: self, action: #selector(finishPINSetup))
    }
    
    private var retryCounter: Int = 3
    
    // MARK: Private Methods
    
    private func setupView() {
        isPINUnlockSuccessful = false
        
        index = 0
        
        title = mode.title
        detailLabel?.text = mode.detail
        
        switch mode {
        case .create:
            createPinDictionary = [Int: Int?]()
            confirmPinDictionary = [Int: Int?]()
            
            biometricButton?.isUserInteractionEnabled = false
            biometricButton?.setImage(nil, for: .normal)
            
            navigationItem.setLeftBarButton(isSettingsScene ? cancelBarButton : skipBarButton, animated: false)
            
        case .confirm:
            confirmPinDictionary = [Int: Int?]()
            
            biometricButton?.isUserInteractionEnabled = false
            biometricButton?.setImage(nil, for: .normal)
            
            navigationItem.setLeftBarButton(isSettingsScene ? cancelBarButton : skipBarButton, animated: false)
            
        case .unlock:
            unlockPinDictionary = [Int: Int?]()
            
            let isBiometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            let biometryType = context.biometryType
            if isBiometricAvailable && biometryType == .touchID {
                biometricButton?.isUserInteractionEnabled = true
                biometricButton?.setImage(UIImage(systemName: "touchid"), for: .normal)
            } else if isBiometricAvailable && biometryType == .faceID {
                biometricButton?.isUserInteractionEnabled = true
                biometricButton?.setImage(UIImage(systemName: "faceid"), for: .normal)
            } else {
                biometricButton?.isUserInteractionEnabled = false
                biometricButton?.setImage(nil, for: .normal)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
                self.navigationItem.setRightBarButton(self.resetWalletBarButton, animated: false)
            }
        }
    }
    
    private func biometricLogin() {
        guard mode == .unlock, DataStore.shared.hasPINEnabled else { return }
        
        let reason = "pin.biometric.message".localized
        context.localizedFallbackTitle = "pin.biometric.title".localized
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason, reply: { success, error in
            DispatchQueue.main.async {
                guard success else {
                    self.mode = .unlock
                    return
                }
                
                self.isPINUnlockSuccessful = true
                self.performSegue(withIdentifier: "unwindToLaunch", sender: nil)
            }
        })
    }
    
    private func updateImageView() {
        let fill = UIImage(systemName: "circle.fill")
        let unfill = UIImage(systemName: "circle")
        
        pin1ImageView?.image = (index > 0) ? fill : unfill
        pin2ImageView?.image = (index > 1) ? fill : unfill
        pin3ImageView?.image = (index > 2) ? fill : unfill
        pin4ImageView?.image = (index > 3) ? fill : unfill
    }
    
    private func validatePin() {
        if mode == .create {
            if createPinDictionary.count == 4 {
                mode = .confirm
            }
        } else if mode == .confirm {
            if confirmPinDictionary.count == 4 {
                guard let userPin = createPinDictionary as? [Int: Int],
                      userPin[0] == confirmPinDictionary[0], userPin[1] == confirmPinDictionary[1],
                      userPin[2] == confirmPinDictionary[2], userPin[3] == confirmPinDictionary[3] else {
                          showConfirmation(title: "pin.confirmation.title".localized,
                                           message: "pin.confirmation.message".localized,
                                           actions: [("pin.confirmation.skip".localized, IBMAlertActionStyle.cancel), ("pin.confirmation.startOver".localized, IBMAlertActionStyle.default)],
                                           completion: { index in
                              if index == 0 {
                                  self.finishPINSetup()
                              } else if index == 1 {
                                  self.mode = .create
                              }
                          })
                          return
                      }
                
                completeSetup(userPin: userPin)
            }
        } else if mode == .unlock {
            if unlockPinDictionary.count == 4 {
                guard let userPin = DataStore.shared.userPIN,
                      userPin[0] == unlockPinDictionary[0], userPin[1] == unlockPinDictionary[1],
                      userPin[2] == unlockPinDictionary[2], userPin[3] == unlockPinDictionary[3] else {
                          retryCounter -= 1
                          
                          let actions = (retryCounter <= 0) ? [("pin.retry".localized, IBMAlertActionStyle.cancel), ("pin.reset.title".localized, IBMAlertActionStyle.destructive)] : [("pin.retry".localized, IBMAlertActionStyle.cancel)]
                          showConfirmation(title: "pin.invalid.title".localized,
                                           message: "pin.invalid.message".localized,
                                           actions: actions,
                                           completion: { index in
                              if index == 0 {
                                  self.mode = .unlock
                              } else if index == 1 {
                                  self.resetWallet()
                              }
                          })
                          return
                      }
                
                isPINUnlockSuccessful = true
                performSegue(withIdentifier: "unwindToLaunch", sender: nil)
            }
        }
    }
    
    private func completeSetup(userPin: [Int: Int]) {
        let title = "pin.complete.title".localized
        var message = "pin.complete.message".localized
        
        let isBiometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        let isFaceIDSupported = isBiometricAvailable && (context.biometryType == .faceID)
        let isTouchIDSupported = isBiometricAvailable && (context.biometryType == .touchID)
        
        if isFaceIDSupported {
            message = "pin.complete.faceID".localized
        } else if isTouchIDSupported {
            message = "pin.complete.touchID".localized
        }
        
        showConfirmation(title: title,
                         message: message,
                         actions: [("pin.complete.continue".localized, IBMAlertActionStyle.cancel)],
                         completion: { _ in
            DataStore.shared.userPIN = userPin
            self.isPINUnlockSuccessful = true
            self.finishPINSetup()
        })
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
