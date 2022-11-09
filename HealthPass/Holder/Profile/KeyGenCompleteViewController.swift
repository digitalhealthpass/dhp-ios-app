//
//  KeyGenCompleteViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class KeyGenCompleteViewController: UIViewController {
    
    var keyPairDictionary: [String: Any?]? {
        didSet {
            updateView()
        }
    }
    
    @IBOutlet var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet var addBarButtonItem: UIBarButtonItem!
    
    @IBOutlet var placeholderView: UIView!
    @IBOutlet var keyPairView: UIView!
    
    @IBOutlet weak var keyTagLabel: UILabel!
    @IBOutlet weak var keyTimestampLabel: UILabel!
    
    @IBOutlet weak var publicKeyLabel: UILabel!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        cancelBarButtonItem.isEnabled = false
        addBarButtonItem.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cancelBarButtonItem.isEnabled = false
        addBarButtonItem.isEnabled = false
        
        updateView()
    }
    
    @IBAction func onCancel(_ sender: Any) {
        generateImpactFeedback()
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onAddToWallet(_ sender: Any) {
        generateImpactFeedback()
        
        cancelBarButtonItem.isEnabled = false
        addBarButtonItem.isEnabled = false
        
        keyPairView?.isHidden = true
        placeholderView?.isHidden = false
        
        if let dictionary = constructDictionary() {
            DataStore.shared.saveKeyPair(dictionary) { result in
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    self.showConfirmationToast()
                    self.generateNotificationFeedback(.success)
                    
                    DataStore.shared.loadUserData()
                    NotificationCenter.default.post(name: ProfileTableViewController.RefreshKeychainIdentifier, object: nil)

                    self.keyPairView?.isHidden = false
                    self.placeholderView?.isHidden = true
                }
            }
        } else {
            //TODO:error handling here
            generateNotificationFeedback(.error)
            
            keyPairView?.isHidden = false
            placeholderView?.isHidden = true
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private let unwindToWalletSegue = "unwindToWallet"
    
    private let toast = Toast()
    
    private var tag: String?
    private var date: Date?
    
    private var publickeySecString: String?
    private var publickeySecData: Data? {
        didSet {
            publickeySecString = publickeySecData?.base64EncodedString()
        }
    }

    private var privatekeySecString: String?
    private var privatekeySecData: Data? {
        didSet {
            privatekeySecString = privatekeySecData?.base64EncodedString()
        }
    }

    // MARK: - Private Methods
    
    private func updateView() {
        
        keyPairView?.isHidden = false
        
        cancelBarButtonItem?.isEnabled = true
        addBarButtonItem?.isEnabled = true
        
        if let tag = keyPairDictionary?["tag"] as? String, !tag.isEmpty {
            self.tag = tag
            keyTagLabel?.text = tag
        } else {
            self.tag = nil
            keyTagLabel?.text = "profile.untitled".localized
        }
        
        if let date = keyPairDictionary?["timestamp"] as? Date {
            self.date = date
            keyTimestampLabel?.text = Date.stringForDate(date: date, dateFormatPattern: .keyGenFormat)
        } else {
            self.date = nil
            keyTimestampLabel?.text = String("-")
        }
        
        if let publickey = keyPairDictionary?["publickey"] {
            let publickeySec = publickey as! SecKey
            self.publickeySecData = try? KeyGen.decodeKeyToData(publickeySec)
            self.publicKeyLabel?.text = publickeySecString
        } else {
            self.publickeySecData = nil
            self.publicKeyLabel?.text = String("-")
        }
        
        if let privatekey = keyPairDictionary?["privatekey"] {
            let privatekeySec = privatekey as! SecKey
            self.privatekeySecData = try? KeyGen.decodeKeyToData(privatekeySec)
        } else {
            self.privatekeySecData = nil
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
    
    private func showConfirmationToast() {
        toast.label.text = "wallet.success".localized
        toast.glyph.image = UIImage(systemName: "wallet.pass")

        toast.layer.setValue("0.01", forKeyPath: "transform.scale")
        toast.alpha = 0
        view.addSubview(toast)
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: [.beginFromCurrentState], animations: {
            self.toast.alpha = 1
            self.toast.layer.setValue(1, forKeyPath: "transform.scale")
            UIAccessibility.post(notification: .screenChanged, argument: self.toast.label)
        }) { (completion) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.beginFromCurrentState], animations: {
                    self.toast.alpha = 0
                    self.toast.layer.setValue(0.8, forKeyPath: "transform.scale")
                }) { (completion) in
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}
