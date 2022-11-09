//
//  ContactDetailsTableViewController+Connection.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit

extension ContactDetailsTableViewController { //Download
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Methods - Download Table
    
    internal func numberOfSectionsConnection(in tableView: UITableView) -> Int {
        if contact?.contactInfoType == .both {
            return 8
        } else if contact?.contactInfoType == .upload {
            return 7
        } else if contact?.contactInfoType == .download {
            return 6
        }
        
        return 0
    }
    
    internal func tableViewConnection(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let numberOfSections = tableView.numberOfSections
        
        if section == 1, contact?.contactInfoType == .both || contact?.contactInfoType == .download {
            return "contact.downloads".localized
        } else if section == 1, contact?.contactInfoType == .upload {
            return "contact.shared".localized
        } else if section == 2, contact?.contactInfoType == .both {
            return "contact.shared".localized
        } else if section == numberOfSections - 5 && contact?.contactInfoType == .upload ||
                    section == numberOfSections - 4 && contact?.contactInfoType == .download {
            return idFields.isEmpty ? nil : "contact.info".localized
        } else if section == numberOfSections - 4 && contact?.contactInfoType != .download ||
                    section == numberOfSections - 3 && contact?.contactInfoType == .download {
            return profileFields.isEmpty ? nil : "contact.registration".localized
        }
        
        return nil
    }
    
    internal func tableViewConnection(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfSections = tableView.numberOfSections
        
        if section == 1, contact?.contactInfoType == .both || contact?.contactInfoType == .download {
            return numberOfRowsForDownloadedCredential
        } else if (section == 1 && contact?.contactInfoType == .upload) || (section == 2 && contact?.contactInfoType == .both) {
            return numberOfRowsForUploadedCredential
        } else if section == numberOfSections - 5 && contact?.contactInfoType != .download ||
                    section == numberOfSections - 4 && contact?.contactInfoType == .download {
            return idFields.count
        } else if section == numberOfSections - 4 && contact?.contactInfoType != .download ||
                    section == numberOfSections - 3 && contact?.contactInfoType == .download {
            return profileFields.count
        }
        
        return 1
    }
    
    internal func tableViewConnection(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let contact = self.contact else {
            return UITableViewCell()
        }
        
        let numberOfSections = tableView.numberOfSections
        
        if indexPath.section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "ContactBasicCell", for: indexPath) as? ContactBasicTableViewCell {
            cell.populateCell(with: contact)
            cell.delegate = self
            return cell
        } else if indexPath.section == 1, contact.contactInfoType == .both || contact.contactInfoType == .download {
            if let downloadedPackages = downloadedPackages, downloadedPackages.count > 0, indexPath.row < downloadedPackages.count,
               let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCredentialCell", for: indexPath) as? ContactCredentialTableViewCell {
                let package = downloadedPackages[indexPath.row]
                cell.populateCell(with: package, isSelected: false)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ContactActionCredentialsCell", for: indexPath)
                cell.textLabel?.text = "contact.download".localized
                
                let addImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
                addImageView.image = UIImage(systemName: "square.and.arrow.down")
                
                cell.accessoryView = addImageView
                
                if !SettingsBundleHelper.shared.savedEnvironment.canShowRegistration {
                    cell.isUserInteractionEnabled = false
                    cell.textLabel?.textColor = .systemGray
                    cell.tintColor = .systemGray
                } else {
                    cell.isUserInteractionEnabled = true
                    cell.textLabel?.textColor = .systemBlue
                    cell.tintColor = .systemBlue
                }
                
                cell.textLabel?.font = AppFont.bodyScaled
                
                return cell
            }
        } else if (indexPath.section == 1 && contact.contactInfoType == .upload) || (indexPath.section == 2 && contact.contactInfoType == .both) {
            if let uploadedPackages = uploadedPackages, uploadedPackages.count > 0, indexPath.row < uploadedPackages.count,
               let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCredentialCell", for: indexPath) as? ContactCredentialTableViewCell {
                let package = uploadedPackages[indexPath.row]
                cell.populateCell(with: package, isSelected: false)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ContactActionCredentialsCell", for: indexPath)
                cell.textLabel?.text = "contact.upload".localized
                
                let addImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
                addImageView.image = UIImage(systemName: "plus")
                
                cell.accessoryView = addImageView
                
                cell.textLabel?.font = AppFont.bodyScaled

                return cell
            }
        } else if indexPath.section == numberOfSections - 5 && contact.contactInfoType != .download ||
                    indexPath.section == numberOfSections - 4 && contact.contactInfoType == .download {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactRegistrationCell", for: indexPath)
            
            let field = self.idFields[indexPath.row]
            
            cell.textLabel?.text = field.localizedPath ?? String("-")
            if let value = field.value {
                cell.detailTextLabel?.text = String(describing: value)
            } else {
                cell.detailTextLabel?.text = "-"
            }
            
            cell.textLabel?.font = AppFont.bodyScaled
            cell.detailTextLabel?.font = AppFont.bodyScaled

            return cell
        } else if indexPath.section == numberOfSections - 4 && contact.contactInfoType != .download ||
                    indexPath.section == numberOfSections - 3 && contact.contactInfoType == .download {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactInfoCell", for: indexPath)
            
            let field = self.profileFields[indexPath.row]
            
            cell.textLabel?.text = field.localizedPath ?? String("-")
            if let value = field.value {
                cell.detailTextLabel?.text = String(describing: value)
            } else {
                cell.detailTextLabel?.text = "-"
            }
            
            cell.textLabel?.font = AppFont.bodyScaled
            cell.detailTextLabel?.font = AppFont.bodyScaled

            return cell
        } else if indexPath.section == numberOfSections - 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactDataCell", for: indexPath)
            cell.textLabel?.font = AppFont.bodyScaled
            return cell
        } else if indexPath.section == numberOfSections - 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactDeleteCell", for: indexPath)
            cell.textLabel?.font = AppFont.bodyScaled
            return cell
        } else if indexPath.section == numberOfSections - 3 && contact.contactInfoType != .download {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactKeyCell", for: indexPath)
            cell.textLabel?.font = AppFont.bodyScaled
            return cell
        }
        
        return UITableViewCell()
    }
    
    internal func tableViewConnection(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let numberOfSections = tableView.numberOfSections
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        generateImpactFeedback()
        
        if indexPath.section == 1, contact?.contactInfoType == .both || contact?.contactInfoType == .download {
            if let downloadedPackages = downloadedPackages, downloadedPackages.count > 0, indexPath.row < downloadedPackages.count {
                let package = downloadedPackages[indexPath.row]
                performSegue(withIdentifier: showCredentialDetailsSegue, sender: package)
            } else {
                performSegue(withIdentifier: showDownloadUpload, sender: nil)
            }
        } else if (indexPath.section == 1 && contact?.contactInfoType == .upload) || (indexPath.section == 2 && contact?.contactInfoType == .both) {
            if let uploadedPackages = uploadedPackages, uploadedPackages.count > 0, indexPath.row < uploadedPackages.count {
                let package = uploadedPackages[indexPath.row]
                performSegue(withIdentifier: showCredentialDetailsSegue, sender: package)
            } else if SettingsBundleHelper.shared.savedEnvironment.canShowRegistration {
                performSegue(withIdentifier: showContactCredentialsSegue, sender: nil)
            }
        } else if indexPath.section == numberOfSections - 3 && contact?.contactInfoType != .download {
            performSegue(withIdentifier: showKeyPairDetailsSegue, sender: nil)
        } else if indexPath.section == numberOfSections - 2 {
            performSegue(withIdentifier: showAssociatedDataSegue, sender: nil)
        } else if indexPath.section == numberOfSections - 1 {
            deleteContact()
        }
    }
    
}
