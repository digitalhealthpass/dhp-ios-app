//
//  OpenOptionsTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class OpenOptionsTableViewController: UITableViewController {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var openOptionsAction = OpenOptionsAction.none
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let unwindToWallet = "unwindToWallet"
    
}

extension OpenOptionsTableViewController {
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if #available(iOS 15, *) {
            return 3
        }
        
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else if section == 1 {
            return 1
        } else if section == 2 {
            return 1
        }
        
        return 0
    }

    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                openOptionsAction = OpenOptionsAction.scanQRCode
            }  else if indexPath.row == 1 {
                openOptionsAction = OpenOptionsAction.photosQRCode
            }
        } else if indexPath.section == 1 {
            openOptionsAction = OpenOptionsAction.importSHCExtension
        } else if indexPath.section == 2 {
            openOptionsAction = OpenOptionsAction.appleHealth
        }

        performSegue(withIdentifier: unwindToWallet, sender: openOptionsAction)
    }
    
}
