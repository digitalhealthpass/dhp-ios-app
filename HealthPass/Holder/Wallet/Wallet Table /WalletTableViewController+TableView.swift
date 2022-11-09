//
//  WalletTableViewController+TableView.swift
//  Holder
//
//  Created by Gautham Velappan on 12/2/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit

extension WalletTableViewController {

    internal func handelAddCardAction() {
        generateImpactFeedback()
        
        performSegue(withIdentifier: presentAddOptions, sender: nil)
    }
    
    internal func showNewRegistration() {
        generateImpactFeedback()
        
        performSegue(withIdentifier: presentNewRegistration, sender: nil)
    }

}

extension WalletTableViewController {
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return SettingsBundleHelper.shared.savedEnvironment.canShowRegistration ? 2 : 1
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(40.0)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "WalletTableViewHeaderFooterView") as? WalletTableViewHeaderFooterView else {
            return nil
        }
        
        switch section {
        case 0:
            header.title = "wallet.section.cards".localized
            header.onAddDidTap = handelAddCardAction
        case 1:
            header.title = "wallet.section.connections".localized
            header.onAddDidTap = showNewRegistration
        default:
            return nil
        }
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat(20.0)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return isPackageEmpty ? 1 : packageArray.count
        case 1:
            return isContactEmpty ? 1 : contactsArray.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0  {
            
            guard !isPackageEmpty else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceholderCell", for: indexPath) as! PlaceholderTableViewCell
                cell.setupCell(with: .card)
                return cell
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "CredentialCardCell", for: indexPath) as! CredentialCardTableViewCell
            
            let package = packageArray[indexPath.row]
            cell.populateCell(with: package)
            
            if let selectedPackage = selectedObject as? Package,
               ((package.type == .VC || package.type == .IDHP || package.type == .GHP) && selectedPackage.credential?.id == package.credential?.id) ||
                ((package.type == .SHC) && selectedPackage.jws?.payloadString == package.jws?.payloadString) ||
                ((package.type == .DCC) && selectedPackage.cose?.payload.asData() == package.cose?.payload.asData()) {
                cell.selectedCell()
            } else {
                cell.resetCell()
            }
            
            return cell
            
        } else if indexPath.section == 1 {
            guard !isContactEmpty else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceholderCell", for: indexPath) as! PlaceholderTableViewCell
                cell.setupCell(with: .conection)
                return cell
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCardCell", for: indexPath) as! ContactCardTableViewCell
            
            let contact = contactsArray[indexPath.row]
            cell.populateCell(with: contact)
            
            if let selectedContact = selectedObject as? Contact, selectedContact.profileCredential?.id == contact.profileCredential?.id {
                cell.selectedCell()
            } else {
                cell.resetCell()
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            guard !isPackageEmpty else {
                return UITableView.automaticDimension
            }
            
            return CGFloat(220.0)
        } else if indexPath.section == 1 {
            guard !isContactEmpty else {
                return UITableView.automaticDimension
            }
            
            return CGFloat(90.0)
        }
        
        return CGFloat.zero
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        generateImpactFeedback()
        
        if indexPath.section == 0  {
            guard !isPackageEmpty else {
                self.handelAddCardAction()
                return
            }
            
            selectedObject = packageArray[indexPath.row]
            performSegue(withIdentifier: credentialDetails, sender: selectedObject)
        } else if indexPath.section == 1 {
            guard !isContactEmpty else {
                self.showNewRegistration()
                return
            }
            
            selectedObject = contactsArray[indexPath.row]
            performSegue(withIdentifier: contactDetails, sender: selectedObject)
        } else {
            selectedObject = nil
        }
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
}
