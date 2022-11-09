//
//  SecurityKeysTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class SecurityKeysTableViewController: UITableViewController {
    @IBOutlet var placeholderView: UIView!

    var isKeyPairEmpty: Bool { return keyPairArray.isEmpty }
    var keyPairArray: [AsymmetricKeyPair] = [] {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didRefreshKeychain(notification:)),
                                               name: ProfileTableViewController.RefreshKeychainIdentifier,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        keyPairArray = DataStore.shared.userKeyPairs
    }
    
    @IBAction func onAddKey(_ sender: Any) {
        self.showKeyGenerationAlert()
    }
    
    @objc
    private func didRefreshKeychain(notification: Notification) {
        keyPairArray = DataStore.shared.userKeyPairs
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }

    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties

    private let showKeyGenComplete = "showKeyGenComplete"
    private let showKeyPairDetailsSegue = "showKeyPairDetails"

    // MARK: - Private Methods

    private func showKeyGenerationAlert() {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "profile.keygen.title".localized,
                                      message: "profile.keygen.message".localized,
                                      preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.font = UIFont.textFieldDefaultFont
            textField.placeholder = "profile.keygen.placeholder".localized
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks Generate.
        alert.addAction(UIAlertAction(title: "profile.keygen.generate".localized, style: .default, handler: { [weak alert] (_) in
            self.generateSelectionFeedback()
            
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            let tag = textField?.text
            
            do {
                let keyTuple = try KeyGen.generateNewKeys(tag: tag)
                let keyPairDictionary: [String: Any?] = [
                    "publickey": keyTuple.publickey,
                    "privatekey": keyTuple.privatekey,
                    "tag": tag,
                    "timestamp" : Date() ]
                self.generateNotificationFeedback(.success)
                self.performSegue(withIdentifier: self.showKeyGenComplete, sender: keyPairDictionary)
            } catch {
                self.generateNotificationFeedback(.error)
            }
        }))
        
        // 3. Grab the value from the text field, and print it when the user clicks Generate.
        alert.addAction(UIAlertAction(title: "button.title.cancel".localized, style: .cancel, handler: { _ in
            self.generateSelectionFeedback()
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? CustomNavigationController,
           let keyGenCompleteViewController = navigationController.viewControllers.first as? KeyGenCompleteViewController,
           let keyPairDictionary = sender as? [String: Any?] {
            keyGenCompleteViewController.keyPairDictionary = keyPairDictionary
        } else if let keyPairDetailsTableViewController = segue.destination as? KeyPairDetailsTableViewController, let keyPair = sender as? AsymmetricKeyPair {
            keyPairDetailsTableViewController.keyPair = keyPair
        }
    }
}

extension SecurityKeysTableViewController {
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isKeyPairEmpty {
            tableView.backgroundView = placeholderView
            placeholderView.isHidden = false
            return 0
        }
        
        tableView.backgroundView = nil
        placeholderView.isHidden = true
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(20.0)
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat(20.0)
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keyPairArray.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(90.0)
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "KeyCardCell", for: indexPath) as! KeyCardTableViewCell
        
        let keypair = keyPairArray[indexPath.row]
        cell.populateCell(with: keypair)
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        generateImpactFeedback()
        
        let keypair = keyPairArray[indexPath.row]
        performSegue(withIdentifier: showKeyPairDetailsSegue, sender: keypair)
    }
}
