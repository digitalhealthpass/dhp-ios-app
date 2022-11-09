//
//  TestModeViewController+TableView.swift
//  Verifier
//
//  Created by John Martino on 2021-09-10.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit

extension TestModeViewController: UITableViewDelegate, UITableViewDataSource {
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return testCredentialItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TestCredentialCell") as? TestCredentialCell else {
            return UITableViewCell()
        }
        
        let item = testCredentialItems[indexPath.row]
        cell.populate(testCredentialItem: item)
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.tertiarySystemBackground
       
        cell.backgroundView = backgroundView
        cell.selectedBackgroundView = backgroundView

        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            testCredentialItems.remove(at: indexPath.row)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !tableView.isEditing {
            tableView.deselectRow(at: indexPath, animated: true)
            
            let item = testCredentialItems[indexPath.row]
            self.performSegue(withIdentifier: "showResult", sender: item)
        }
    }
    
}
