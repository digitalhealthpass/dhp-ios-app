//
//  CredentialDetailsTableViewController+TableView.swift
//  Holder
//
//  Created by Gautham Velappan on 12/6/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit

extension CredentialDetailsTableViewController {
    
    // ======================================================================
    // === UITableView ======================================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 || section == 1 || section == (numberOfSections-(hasCredentialInfo ? 4:3)) || section == (numberOfSections-1) {
            return CGFloat.zero
        } else if section == 2 {
            return hasAssociatedConnections ? CGFloat(40.0): CGFloat.zero
        } else if section == 3, hasAssociatedConnections {
            return CGFloat.zero
        } else if hasCredentialInfo, section == (numberOfSections-3) {
            return CGFloat(20.0)
        } else if section == (numberOfSections-2) {
            return CGFloat(20.0)
        } else if package?.type == .SHC || package?.type == .DCC {
            let sortedKeys = Array(displayFieldsDictionary.keys).sorted()
            let key = hasAssociatedConnections ? sortedKeys[section-4] : sortedKeys[section-3]
            let sectionTitle = displayFieldsDictionary[key]?.first?.sectionTitle
            let locale = Locale.current.languageCode ?? "en"
            
            if let value = sectionTitle?[locale], !(value.isEmpty) {
                return CGFloat(40.0)
            }
        } else {
            let keys = Array(fieldsDictionary.keys).sorted()
            let key = hasAssociatedConnections ? keys[section-4] : keys[section-3]
            
            if !(key.isEmpty) {
                return CGFloat(40.0)
            }
        }
        
        return CGFloat.zero
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        
        //Don't update font for card Info
        if hasCredentialInfo, section == (numberOfSections-3) {
            return
        }
        
        //Don't update font for record verification section
        if section == (numberOfSections-2) {
            return
        }

        header.textLabel?.textColor = UIColor.label
        header.textLabel?.font = UIFont(name: AppFont.bold, size: 20)
        header.textLabel?.text = header.textLabel?.text?.capitalized
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 || section == 1 || section == (numberOfSections-(hasCredentialInfo ? 4:3)) || section == (numberOfSections-1) {
            return nil
        } else if section == 2 {
            return hasAssociatedConnections ? "wallet.section.connections".localized: nil
        } else if section == 3, hasAssociatedConnections {
            return nil
        } else if hasCredentialInfo, section == (numberOfSections-3) {
            return "credential.details.cardInfo".localized
        } else if section == (numberOfSections-2) {
            return "credential.details.recordVerification".localized
        } else if package?.type == .SHC || package?.type == .DCC {
            let sortedKeys = Array(displayFieldsDictionary.keys).sorted()
            let key = hasAssociatedConnections ? sortedKeys[section-4] : sortedKeys[section-3]
            let sectionTitle = displayFieldsDictionary[key]?.first?.sectionTitle
            
            let locale = Locale.current.languageCode ?? "en"
            return sectionTitle?[locale]
        } else {
            let keys = Array(fieldsDictionary.keys).sorted()
            let key = hasAssociatedConnections ? keys[section-4] : keys[section-3]
            return key
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat(20.0)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 || section == 1 || section == (numberOfSections-(hasCredentialInfo ? 4:3)) || section == (numberOfSections-1) {
            return 1
        } else if section == 2 {
            return hasAssociatedConnections ? (package?.associatedContacts?.count ?? 0): 1
        } else if section == 3, hasAssociatedConnections {
            return 1
        } else if hasCredentialInfo, section == (numberOfSections-3) {
            return credentialInfo.count
        } else if section == (numberOfSections-2) {
            return recordVerification.count
        } else if package?.type == .SHC || package?.type == .DCC {
            let sortedKeys = Array(displayFieldsDictionary.keys).sorted()
            let key = hasAssociatedConnections ? sortedKeys[section-4] : sortedKeys[section-3]
            return displayFieldsDictionary[key]?.count ?? 0
        } else {
            let keys = Array(fieldsDictionary.keys).sorted()
            let key = hasAssociatedConnections ? keys[section-4] : keys[section-3]
            let sectionFields = fieldsDictionary[key]
            let visibleSectionFields = sectionFields?.filter({ $0.visible ?? true })
            return visibleSectionFields?.count ?? 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let package = self.package else {
            return UITableViewCell()
        }
        
        if indexPath.section == 0,
           let cell = tableView.dequeueReusableCell(withIdentifier: "CredentialCardCell", for: indexPath) as? CredentialCardTableViewCell {
            cell.populateCell(with: package)
            return cell
        } else if indexPath.section == 1,
                  let cell = tableView.dequeueReusableCell(withIdentifier: "CredentialBasicTableViewCell", for: indexPath) as? CredentialBasicTableViewCell {
            cell.delegate = self
            cell.populateCell(with: package)
            return cell
        } else if indexPath.section == 2 {
            if hasAssociatedConnections, let contact = package.associatedContacts?[indexPath.row],
               let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCardCell", for: indexPath) as? ContactCardTableViewCell {
                cell.populateCell(with: contact)
                return cell
            } else if indexPath.section == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CredentialConnectionShareTableViewCell", for: indexPath)
                cell.textLabel?.font = AppFont.headlineScaled
                return cell
            }
        } else if indexPath.section == 3, hasAssociatedConnections {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CredentialConnectionShareTableViewCell", for: indexPath)
            cell.textLabel?.font = AppFont.headlineScaled
            return cell
        } else if hasCredentialInfo, indexPath.section == (numberOfSections-3), let cell = tableView.dequeueReusableCell(withIdentifier: "CredentialInfoTableViewCell", for: indexPath) as? CredentialInfoTableViewCell  {
            let data = credentialInfo[indexPath.row]
            cell.populateCell(with: data)
            return cell
        } else if indexPath.section == (numberOfSections-2), let cell = tableView.dequeueReusableCell(withIdentifier: "CredentialInfoTableViewCell", for: indexPath) as? CredentialInfoTableViewCell  {
            let data = recordVerification[indexPath.row]
            cell.populateCell(with: data)
            return cell
        } else if indexPath.section == (numberOfSections-(hasCredentialInfo ? 4:3)) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CredentialSourceTableViewCell", for: indexPath)
            cell.textLabel?.font = AppFont.bodyScaled
            return cell
        } else if indexPath.section == (numberOfSections-1) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CredentialDeleteTableViewCell", for: indexPath)
            cell.textLabel?.font = AppFont.bodyScaled
            return cell
        } else if let cell = tableView.dequeueReusableCell(withIdentifier: "CredentialInfoTableViewCell", for: indexPath) as? CredentialInfoTableViewCell {
            if package.type == .SHC || package.type == .DCC {
                let sortedKeys = Array(displayFieldsDictionary.keys).sorted()
                let key = hasAssociatedConnections ? sortedKeys[indexPath.section-4] : sortedKeys[indexPath.section-3]
                
                let sectionDisplayFields = displayFieldsDictionary[key]
                
                if let displayField = sectionDisplayFields?[indexPath.row] {
                    cell.populateCell(for: displayField)
                } else {
                    //TODO: Handle error
                }
            } else {
                let keys = Array(fieldsDictionary.keys).sorted()
                let key = hasAssociatedConnections ? keys[indexPath.section-4] : keys[indexPath.section-3]
                
                let sectionFields = fieldsDictionary[key]
                let visibleSectionFields = sectionFields?.filter({ $0.visible ?? true })
                
                let field = visibleSectionFields?[indexPath.row]
                cell.populateCell(for: field, with: package)
            }
            return cell
        }
        
        return UITableViewCell()
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let indexPath = IndexPath(row: 0, section: 2)
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        } else if indexPath.section == 3, hasAssociatedConnections {
            self.performSegue(withIdentifier: self.showConnectionListSegue, sender: nil)
        } else if indexPath.section == 2, !hasAssociatedConnections {
            self.performSegue(withIdentifier: self.showConnectionListSegue, sender: nil)
        } else if indexPath.section == (numberOfSections-(hasCredentialInfo ? 4:3)) {
            performSegue(withIdentifier: showCredentialSourceSegue, sender: nil)
        } else if indexPath.section == (numberOfSections-1) {
            deleteCredentialSelected()
        }
    }
}

