//
//  ConnectionListTableViewController.swift
//  Holder
//
//  Created by Gautham Velappan on 12/7/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class ConnectionListTableViewController: UITableViewController {

    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        isModalInPresentation = true
        
        tableView.tableFooterView = UIView()
        
        contactsArray = DataStore.shared.userContacts.filter { $0.contactInfoType == .upload || $0.contactInfoType == .both }
    }
    // MARK: - @IBOutlet
    @IBOutlet weak var nextBarButtonItem: UIBarButtonItem!
    
    // MARK: - IBAction

    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func onNext(_ sender: UIBarButtonItem) {
        guard let index = currentSelectedConection?.row else {
            return
        }
        
        let contact = contactsArray[index]
        self.performSegue(withIdentifier: self.showConfirmationSegue, sender: contact)
    }
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Properties
    
    var package: Package?

    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private let showConfirmationSegue = "showConfirmation"
    private let unwindToWallet = "unwindToWallet"
    private var currentSelectedConection: IndexPath?
    
    private var contactsArray: [Contact] = [] {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let contactConfirmationTableViewController = segue.destination as? ContactConfirmationTableViewController {
            contactConfirmationTableViewController.package = package
            contactConfirmationTableViewController.contact = sender as? Contact
        }
    
    }

}

extension ConnectionListTableViewController {
    
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(40)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1, !(contactsArray.isEmpty) {
            return String("AVAILABLE CONNECTIONS")
        } else if section == 0 {
            return String("ADD NEW CONNECTION")
        }
        
        return nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return contactsArray.count
        }
        
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCardCell", for: indexPath) as! ContactCardTableViewCell
            
            let contact = contactsArray[indexPath.row]
            cell.populateCell(with: contact)
            
            return cell
        } else if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewContactCardCell", for: indexPath)
            return cell
        }
        
        return UITableViewCell()
    }
    
    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            let newCell = tableView.cellForRow(at: indexPath) as? ContactCardTableViewCell
            
            guard currentSelectedConection != indexPath else {
                currentSelectedConection = nil
                nextBarButtonItem.isEnabled = false
                newCell?.didDeselected()
                return
            }
            
            if let currentSelectedConection = currentSelectedConection {
                let currentCell = tableView.cellForRow(at: currentSelectedConection) as? ContactCardTableViewCell
                currentCell?.didDeselected()
            }
        
            currentSelectedConection = indexPath
            nextBarButtonItem.isEnabled = true
            newCell?.didSelected()
        } else if indexPath.section == 0 {
            self.performSegue(withIdentifier: self.unwindToWallet, sender: nil)
        }
    }

}
