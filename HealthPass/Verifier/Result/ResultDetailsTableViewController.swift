//
//  ResultDetailsTableViewController.swift
//  Verifier
//
//  Created by Gautham Velappan on 3/9/22.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import VerifiableCredential
import VerificationEngine

class ResultDetailsTableViewController: UITableViewController {

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        UIView.performWithoutAnimation {
            self.tableView?.reloadData()
        }
    }

    // MARK: - IBOutlet
    
    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem?

    // MARK: - IBAction
    
    @IBAction func onDone(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties

    internal var successfulRules: [Rule]?
    internal var failedRules: [Rule]?

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return successfulRules?.count ?? 0
        } else if section == 1 {
            return failedRules?.count ?? 0
        }
        
        return 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Successful Rules"
        } else if section == 1 {
            return "Failed Rules"
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultDetailsReuseIdentifier", for: indexPath)

        var rule: Rule?
        if indexPath.section == 0 {
            cell.textLabel?.textColor = .label
            rule = successfulRules?[indexPath.row]
        } else if indexPath.section == 1 {
            cell.textLabel?.textColor = .systemRed
            rule = failedRules?[indexPath.row]
        }
        
        cell.textLabel?.text = rule?.name
        cell.detailTextLabel?.text = rule?.id

        return cell
    }

}
