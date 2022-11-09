//
//  KeyPairManagementDetailsTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class KeyPairManagementDetailsTableViewController: UITableViewController {
    
    var keyTag: String?
    
    var keyPair: [String: Any?]? {
        didSet {
            if keyPair == nil {
                generateNewKeyPair()
            } else {
                updateView()
            }
        }
    }
    
    var generatedKeyPair: [String: Any?]? {
        didSet {
            updateView()
        }
    }
    
    @IBOutlet weak var keyTagLabel: UILabel!
    @IBOutlet weak var keyTimestampLabel: UILabel!
    
    @IBOutlet weak var publicKeyLabel: UILabel!
    @IBOutlet weak var privateKeyLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = nil
        updateView()
    }
    
    @IBAction func onDone(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private let toast = Toast()
    
    private var tag: String?
    private var date: Date?
    
    private var publickeySecString: String? {
        didSet {
            didFinishLoading = (publickeySecString != nil) && (privatekeySecString != nil)
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
    
    private var didFinishLoading = false {
        didSet {
            if didFinishLoading {
                if generatedKeyPair != nil, let dictionary = self.constructDictionary() {
                    if !isSavingKeyPair {
                        self.saveKeyPair(dictionary: dictionary)
                    }
                } else {
                    copyPublicKey()
                }
            }
            
        }
    }
    
    private var isSavingKeyPair = false
    
    // MARK: - Private Methods
    
    private func updateTag(for dictionary: [String : Any?]) {
        if let tag = dictionary["tag"] as? String, !tag.isEmpty {
            self.tag = tag
            keyTagLabel?.text = tag
        } else {
            self.tag = nil
            keyTagLabel?.text = "kpm.untitled".localized
        }
    }
    
    private func updateTimestamp(for dictionary: [String : Any?]) {
        if let date = dictionary["timestamp"] as? Date {
            self.date = date
            keyTimestampLabel?.text = Date.stringForDate(date: date, dateFormatPattern: .keyGenFormat)
        } else if let dateString = dictionary["timestamp"] as? String {
            self.date = nil
            keyTimestampLabel?.text = dateString
        } else {
            self.date = nil
            keyTimestampLabel?.text = String("-")
        }
    }
    
    private func updatePublic(for dictionary: [String : Any?]) {
        if let publickeyString = dictionary["publickey"] as? String {
            self.publickeySecString = publickeyString
            self.publicKeyLabel?.text = publickeyString
        } else if let publickey = dictionary["publickey"] {
            let publickeySec = publickey as! SecKey
            self.publickeySecData = try? KeyGen.decodeKeyToData(publickeySec)
            self.publicKeyLabel?.text = publickeySecString
        } else {
            self.publickeySecData = nil
            publicKeyLabel?.text = String("-")
        }
    }
    
    private func updatePrivate(for dictionary: [String : Any?]) {
        if let privatekey = dictionary["privatekey"] as? String {
            self.privatekeySecString = privatekey
            self.privateKeyLabel?.text = privatekey
        } else if let privatekey = dictionary["privatekey"] {
            let privatekeySec = privatekey as! SecKey
            self.privatekeySecData = try? KeyGen.decodeKeyToData(privatekeySec)
            self.privateKeyLabel?.text = privatekeySecString
        } else {
            self.privatekeySecData = nil
            privateKeyLabel?.text = String("-")
        }
    }
    
    private func updateView() {
        var dictionary: [String : Any?]?
        
        if let generatedKeyPair = generatedKeyPair {
            dictionary = generatedKeyPair
        } else if let existingKeyPair = keyPair {
            dictionary = existingKeyPair
            didFinishLoading = true
        }
        
        if let dictionary = dictionary {
            updateTag(for: dictionary)
            updateTimestamp(for: dictionary)
            updatePublic(for: dictionary)
            updatePrivate(for: dictionary)
        }
    }
    
    private func generateNewKeyPair() {
        do {
            let keyTuple = try KeyGen.generateNewKeys(tag: keyTag)
            self.generatedKeyPair = [ "publickey": keyTuple.publickey,
                                      "privatekey": keyTuple.privatekey,
                                      "tag": keyTag,
                                      "timestamp" : Date() ]
        } catch {
            self.generatedKeyPair = nil
            self.generateNotificationFeedback(.error)
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
    
    private func saveKeyPair(dictionary: [String : Any]) {
        isSavingKeyPair = true
        DataStore.shared.saveKeyPair(dictionary) { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.copyPublicKey()
                
                DataStore.shared.loadUserData()
                NotificationCenter.default.post(name: ProfileTableViewController.RefreshKeychainIdentifier, object: nil)
            }
        }
    }
    
    private func copyPublicKey() {
        self.generateImpactFeedback()
        
        let board = UIPasteboard.general
        if let publickey = publickeySecString {
            board.string = publickey
            
            self.showCopyConfirmationToast()
            self.generateNotificationFeedback(.success)
        }
    }
    
    private func showCopyConfirmationToast() {
        navigationItem.title = String(format: "kpm.navigationTitleFormat".localized, "\(Date.stringForDate(date: Date(), dateFormatPattern: .hourMinSecTimePattern))")
            
        toast.label.text = "kpm.label".localized
        toast.glyph.image = UIImage(systemName: "doc.on.clipboard")
        
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
                })
            }
        }
    }
}

extension KeyPairManagementDetailsTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 && indexPath.row == 0 {
            copyPublicKey()
        }
    }
}
