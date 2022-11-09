//
//  KeyPairDetailsTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

protocol KeyPairDetailsTableViewControllerDelegate: AnyObject {
    func deleteKeyPairSelected()
}

class KeyPairDetailsTableViewController: UITableViewController {
    
    var keyPair: AsymmetricKeyPair?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorColor = UIColor(white: 0.85, alpha: 1.0)
        tableView.tableFooterView = UIView()
        
        title = keyPair?.tag ?? "kpm.untitled".localized
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didRefreshKeychain(notification:)),
                                               name: ProfileTableViewController.RefreshKeychainIdentifier,
                                               object: nil)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let contactDetailsTableViewController = segue.destination as? ContactDetailsTableViewController, let contact = sender as? Contact {
            contactDetailsTableViewController.contact = contact
        }
    }
    
    @objc
    func didRefreshKeychain(notification: Notification) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    private let toast = Toast()
    
    // MARK: - Private Methods
    
    private func copyPublicKey() {
        self.generateImpactFeedback()
        
        let board = UIPasteboard.general
        if let publickey = keyPair?.publickey {
            board.string = publickey
            
            self.showCopyConfirmationToast()
            self.generateNotificationFeedback(.success)
        }
    }
    
    private func showCopyConfirmationToast() {
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

extension KeyPairDetailsTableViewController {
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            if !(keyPair?.canDelete ?? false) {
                return CGFloat(100.0)
            }
            
            return CGFloat(60.0)
        }
        
        return CGFloat(10.0)
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = UIFont(name: AppFont.bold, size: 20)
        header.textLabel?.textColor = UIColor.label
        header.backgroundColor = UIColor.secondarySystemBackground
        header.textLabel?.text = header.textLabel?.text?.capitalized
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            if !(keyPair?.canDelete ?? false) {
                return "kpm.headerTitle".localized
            }
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "kpm.footerTitle".localized
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 4
        } else if section == 1 {
            if keyPair?.canDelete ?? false {
                return 1
            } else {
                return keyPair?.associatedContacts.count ?? 0
            }
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            if !(keyPair?.canDelete ?? false) {
                return CGFloat(90.0)
            }
        }
        
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let keyPair = keyPair else {
            return UITableViewCell()
        }
        
        if indexPath.section == 0, indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "KeyPairTagTableViewCell", for: indexPath)
            if let tag = keyPair.tag {
                cell.detailTextLabel?.text = tag
            } else {
                cell.detailTextLabel?.text = "kpm.untitled".localized
            }
            
            return cell
        } else if indexPath.section == 0, indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "KeyPairDateTableViewCell", for: indexPath)
            if let date = keyPair.timestamp {
                cell.detailTextLabel?.text = date
            } else {
                cell.detailTextLabel?.text = String("-")
            }
            return cell
        } else if indexPath.section == 0, indexPath.row == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "KeyPairTitleValueTableViewCell", for: indexPath)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)
            return cell
        } else if indexPath.section == 0, indexPath.row == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "KeyPairValueTableViewCell", for: indexPath)
            if let publickey = keyPair.publickey {
                cell.textLabel?.text = publickey
            } else {
                cell.textLabel?.text = String("-")
            }
            return cell
        } else if indexPath.section == 1 {
            if keyPair.canDelete {
                let cell = tableView.dequeueReusableCell(withIdentifier: "KeyPairDeleteTableViewCell", for: indexPath)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "KeyPairContactTableViewCell", for: indexPath) as! ContactCardTableViewCell
                
                let contact = keyPair.associatedContacts[indexPath.row]
                cell.populateCell(with: contact)
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0, (indexPath.row == 2 || indexPath.row == 3) {
            copyPublicKey()
        } else if indexPath.section == 1 {
            if keyPair?.canDelete ?? false {
                deleteKeyPairSelected()
            }
        }
    }
    
}

extension KeyPairDetailsTableViewController : KeyPairDetailsTableViewControllerDelegate {
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }
    
    func deleteKeyPairSelected() {
        generateImpactFeedback()
        
        guard let keyPairDictionary = self.keyPair?.rawDictionary else {
            return
        }
        
        self.showConfirmation(title: "kpm.delete.title".localized, message: "kpm.delete.message".localized,
                              actions: [("kpm.delete.confirm".localized, IBMAlertActionStyle.destructive), ("button.title.cancel".localized, IBMAlertActionStyle.cancel)],
                              completion: { index in
                                self.generateSelectionFeedback()
                                if index == 0 {
                                    DataStore.shared.deletekeyPair(keyPairDictionary) { _ in
                                        self.generateNotificationFeedback(.error)
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                                            DataStore.shared.loadUserData()
                                            self.navigationController?.popViewController(animated: true)
                                        }
                                    }
                                }
                              })
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
}
