//
//  ContactCredentialTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class ContactCredentialTableViewController: UITableViewController {
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
    }
    // MARK: - IBOutlet
    
    @IBOutlet var nextBarButtonItem: UIBarButtonItem!
    
    @IBOutlet var tableViewPlaceholder: UIView!
    
    // MARK: - IBAction
    
    @IBAction func onNextItem(_ sender: UIBarButtonItem) {
        //Check if the user selected from already uploaded list
        if sharablePackageArray.isEmpty || indexPathsForSelectedRows.compactMap({ $0.section }).contains(1) {
            showConfirmation(title: "contact.credentials.reupload.title".localized,
                             message: "contact.credentials.reupload.message".localized,
                             actions: [("button.title.cancel".localized, IBMAlertActionStyle.cancel), ("contact.credentials.reupload.yes".localized, IBMAlertActionStyle.default)]) { index in
                if index == 1 {
                    var selectedPackages = [Package]()
                    selectedPackages = self.indexPathsForSelectedRows.compactMap {
                        if self.sharablePackageArray.isEmpty {
                            return self.uploadedPackages?[$0.row]
                        } else {
                            if $0.section == 0 {
                                return self.sharablePackageArray[$0.row]
                            } else if $0.section == 1 {
                                return self.uploadedPackages?[$0.row]
                            }
                        }
                        
                        return nil
                    }
                    self.performSegue(withIdentifier: self.showContactConsentSegue, sender: selectedPackages)
                }
            }
            return
        }
        
        let selectedPackages = indexPathsForSelectedRows.compactMap { sharablePackageArray[$0.row] }
        performSegue(withIdentifier: showContactConsentSegue, sender: selectedPackages)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let contactConsentTableViewController = segue.destination as? ContactConsentTableViewController {
            contactConsentTableViewController.uploadedPackages = uploadedPackages
            contactConsentTableViewController.selectedPackages = (sender as? [Package]) ?? [Package]()
            contactConsentTableViewController.contact = contact
        }
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var contact: Contact?
    
    var uploadedPackages: [Package]? {
        didSet {

            guard !DataStore.shared.userPackages.isEmpty else {
                self.numberOfSections = 0
                return
            }
            
            guard let uploadedPackages = uploadedPackages, !(uploadedPackages.isEmpty) else {
                self.sharablePackageArray = DataStore.shared.userPackages
                self.numberOfSections = 1
                
                return
            }
            
            let userPackages = DataStore.shared.userPackages
            var filteredPackageArray = [Package]()
            userPackages.forEach { package in
                if !(uploadedPackages.contains(where: { $0.verifiableObject?.uploadIdentifier == package.verifiableObject?.uploadIdentifier } )) {
                    filteredPackageArray.append(package)
                }
            }
            
            sharablePackageArray = filteredPackageArray
            self.numberOfSections = !sharablePackageArray.isEmpty ? 2 : 1
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    private var indexPathsForSelectedRows: [IndexPath] = [] {
        didSet {
            nextBarButtonItem.isEnabled = !(indexPathsForSelectedRows.isEmpty)
        }
    }
    
    private var sharablePackageArray: [Package] = []
    
    private var numberOfSections = 0 {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    private let showContactConsentSegue = "showContactConsent"
}

extension ContactCredentialTableViewController {
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = (numberOfSections == 0) ? tableViewPlaceholder : nil
        tableViewPlaceholder.isHidden = !(numberOfSections == 0)
        
        return numberOfSections
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return !(sharablePackageArray.isEmpty) ? "contact.credentials.available".localized : "contact.credentials.shared".localized
        } else if section == 1 {
            return !(uploadedPackages?.isEmpty ?? true) ? "contact.credentials.shared".localized : nil
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return !(sharablePackageArray.isEmpty) ? sharablePackageArray.count : uploadedPackages?.count ?? 0
        } else if section == 1 {
            return uploadedPackages?.count ?? 0
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCredentialCell", for: indexPath) as? ContactCredentialTableViewCell {
            
            let isSelected = indexPathsForSelectedRows.contains(indexPath)
            
            if indexPath.section == 0, !sharablePackageArray.isEmpty {
                let package = sharablePackageArray[indexPath.row]
                cell.populateCell(with: package, isSelected: isSelected)
            } else if indexPath.section == 0, sharablePackageArray.isEmpty, let package = uploadedPackages?[indexPath.row] {
                cell.populateCell(with: package, isSelected: isSelected)
            } else if indexPath.section == 1, let package = uploadedPackages?[indexPath.row] {
                cell.populateCell(with: package, isSelected: isSelected)
            } else {
                return UITableViewCell()
            }

            return cell
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        generateImpactFeedback()
        
        if let index = indexPathsForSelectedRows.lastIndex(of: indexPath) {
            indexPathsForSelectedRows.remove(at: index)
        } else {
            indexPathsForSelectedRows.append(indexPath)
        }
        
        self.tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
