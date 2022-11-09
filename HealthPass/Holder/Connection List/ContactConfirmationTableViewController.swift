//
//  ContactConfirmationTableViewController.swift
//  Holder
//
//  Created by Gautham Velappan on 12/7/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class ContactConfirmationTableViewController: UITableViewController {
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        tableView.separatorColor = UIColor(white: 0.85, alpha: 1.0)
        tableView.tableFooterView = UIView()
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Properties
    
    var package: Package? {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    var contact: Contact? {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private let showContactConsentSegue = "showContactConsent"
    private let unwindToCredentialDetailsSegue = "unwindToCredentialDetails"
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let contactConsentTableViewController = segue.destination as? ContactConsentTableViewController,
           let package = package {
            contactConsentTableViewController.selectedPackages = [package]
            contactConsentTableViewController.contact = contact
        }
    }
    
}

extension ContactConfirmationTableViewController {
    
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard package != nil, contact != nil else {
            return 0
        }
        
        return 3
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(40)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return String("CARD SELECTED")
        } else if section == 1 {
            return String("CONNECTION SELECTED")
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0, let package = package {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CredentialCardCell", for: indexPath) as! CredentialCardTableViewCell
            cell.populateCell(with: package)
            return cell
        } else if indexPath.section == 1, let contact = contact {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCardCell", for: indexPath) as! ContactCardTableViewCell
            cell.populateCell(with: contact)
            return cell
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CredentialConnectionShareTableViewCell", for: indexPath)
            cell.textLabel?.font = AppFont.headlineScaled
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 2 {
            guard let associatedContactIds = package?.associatedContacts?.compactMap({ $0.idCredential?.id }),
                  let selectedContactId = contact?.idCredential?.id, associatedContactIds.contains(selectedContactId) else {
                      self.performSegue(withIdentifier: showContactConsentSegue, sender: nil)
                      return
                  }
            
            showConfirmation(title: "contact.credentials.reupload.title".localized,
                             message: "contact.credentials.reupload.message2".localized,
                             actions: [("button.title.cancel".localized, IBMAlertActionStyle.cancel), ("contact.credentials.reupload.yes".localized, IBMAlertActionStyle.default)]) { index in
                if index == 1 {
                    self.performSegue(withIdentifier: self.showContactConsentSegue, sender: nil)
                } else {
                    self.performSegue(withIdentifier: self.unwindToCredentialDetailsSegue, sender: nil)
                }
            }
        }
    }
    
}
