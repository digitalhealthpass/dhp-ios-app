//
//  KeyPairManagementTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class KeyPairManagementTableViewController: UITableViewController {
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        keyPairArray = DataStore.shared.userKeyPairs
    }
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showKeyPairManagementDetails,
           let keyPairManagementDetailsTableViewController = segue.destination as? KeyPairManagementDetailsTableViewController {
            keyPairManagementDetailsTableViewController.keyPair = sender as? [String: Any?]
        }
     }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private let showKeyPairManagementDetails = "showKeyPairManagementDetails"

    
}

extension KeyPairManagementTableViewController {
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "kpm.existing".localized
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (section == 0) ? 1 : keyPairArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GenerateNewKeyPairTableViewCell", for: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ExistingKeyPairTableViewCell", for: indexPath)
            let keypair = keyPairArray[indexPath.row]
            
            if let tag = keypair.tag {
                cell.textLabel?.text = tag
            } else {
                cell.textLabel?.text = String("Untitled")
            }
            
            if let date = keypair.timestamp {
                cell.detailTextLabel?.text = date
            } else {
                cell.detailTextLabel?.text = String("-")
            }
            
            return cell
        }
    }
    
}

extension KeyPairManagementTableViewController {
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let keyPair = (indexPath.section == 0) ? nil : keyPairArray[indexPath.row]
        performSegue(withIdentifier: showKeyPairManagementDetails, sender: keyPair)
    }

}
