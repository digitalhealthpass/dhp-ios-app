//
//  CredentialQRCodeViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class CredentialQRCodeViewController: UIViewController {
    
    var package: Package?
    
    var originalBrightness = CGFloat.zero
    
    @IBOutlet weak var qrCodeImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        originalBrightness = UIScreen.main.brightness
        
        package?.fetchQRCodeImage { image, _ in
            self.qrCodeImageView?.image = image
            self.qrCodeImageView?.isUserInteractionEnabled = true
            self.qrCodeImageView?.isAccessibilityElement = true
            let accessibilityText = "accessibility.qrcode".localized
            self.qrCodeImageView?.accessibilityLabel = accessibilityText
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didRefreshKeychain(notification:)),
                                               name: ProfileTableViewController.RefreshKeychainIdentifier,
                                               object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIScreen.main.brightness = CGFloat(1.0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIScreen.main.brightness = originalBrightness
    }
    
    @objc
    func didRefreshKeychain(notification: Notification) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func onClose(_ sender: Any) {
        generateImpactFeedback()
        
        dismiss(animated: true, completion: nil)
    }
    
}
