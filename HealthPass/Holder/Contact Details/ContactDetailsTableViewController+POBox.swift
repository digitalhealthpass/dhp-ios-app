//
//  ContactDetailsTableViewController+POBox.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit

extension ContactDetailsTableViewController { // PO BOX
    // ======================================================================
    // MARK: - internal
    // ======================================================================
    
    // MARK: internal Methods - PO BOX Table
    
    internal func numberOfSectionsPOBox(in tableView: UITableView) -> Int {
        return 7
    }
        
    internal func tableViewPOBox(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "contact.section.title1".localized
        } else if section == 2 {
            return "contact.section.title2".localized
        } else if section == 3 {
            return "contact.section.title3".localized
        }
        
        return nil
    }
    
    internal func tableViewPOBox(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 || section == 4 || section == 5 || section == 6 {
            return 1
        } else if section == 1 {
            return numberOfRowsForUploadedCredential
        } else if section == 2 {
            return 5
        } else if section == 3 {
            return 4
        }
        
        return 0
    }
    
    internal func tableViewPOBox(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let contact = self.contact else {
            return UITableViewCell()
        }
        
        if indexPath.section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "ContactBasicCell", for: indexPath) as? ContactBasicTableViewCell {
            cell.populateCell(with: contact)
            cell.delegate = self
            return cell
        } else if indexPath.section == 1 {
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
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactInfoCell", for: indexPath)
            
            var textLabelString = String()
            var detailTextLabelString = String()
            
            let credentialSubject = contact.profileCredential?.extendedCredentialSubject
            
            let piiController = credentialSubject?.consentInfo?.piiControllers?.first
            
            if indexPath.row == 0 {
                textLabelString = "contact.name".localized
                detailTextLabelString = piiController?.contact ?? String("-")
            } else if indexPath.row == 1 {
                textLabelString = "contact.phone".localized
                detailTextLabelString = piiController?.phone ?? String("-")
            } else if indexPath.row == 2 {
                textLabelString = "contact.email".localized
                detailTextLabelString = piiController?.email?.lowercased() ?? String("-")
            } else if indexPath.row == 3 {
                textLabelString = "contact.address".localized
                
                if let line = piiController?.address?.line {
                    detailTextLabelString = String(format: "%@", line)
                }
                
                if let city = piiController?.address?.city {
                    detailTextLabelString = String(format: "%@\n%@", detailTextLabelString, city)
                }
                if let state = piiController?.address?.state {
                    detailTextLabelString = String(format: "%@, %@", detailTextLabelString, state)
                }
                if let postalCode = piiController?.address?.postalCode {
                    detailTextLabelString = String(format: "%@ %@", detailTextLabelString, postalCode)
                }
                if let country = piiController?.address?.country {
                    detailTextLabelString = String(format: "%@\n%@", detailTextLabelString, country)
                }
            } else if indexPath.row == 4 {
                textLabelString = "contact.website".localized
                detailTextLabelString = piiController?.piiControllerUrl?.lowercased() ?? String("-")
            }
            
            cell.textLabel?.text = textLabelString
            cell.detailTextLabel?.text = detailTextLabelString
            
            cell.textLabel?.font = AppFont.bodyScaled
            cell.detailTextLabel?.font = AppFont.bodyScaled

            return cell
        } else if indexPath.section == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactRegistrationCell", for: indexPath)
            
            let credentialSubject = contact.idCredential?.extendedCredentialSubject
            var textLabelString = String()
            var detailTextLabelString = String()
            
            if indexPath.row == 0 {
                textLabelString = "contact.gender".localized
                detailTextLabelString = credentialSubject?.gender ?? String("-")
            } else if indexPath.row == 1 {
                textLabelString = "contact.age".localized
                detailTextLabelString = credentialSubject?.ageRange ?? String("-")
            } else if indexPath.row == 2 {
                textLabelString = "contact.race".localized
                detailTextLabelString = credentialSubject?.race?.joined(separator: ", ") ?? String("-")
            } else if indexPath.row == 3 {
                textLabelString = "contact.location".localized
                detailTextLabelString = credentialSubject?.location?.uppercased() ?? String("-")
            }
            
            cell.textLabel?.text = textLabelString
            cell.detailTextLabel?.text = detailTextLabelString
            
            cell.textLabel?.font = AppFont.bodyScaled
            cell.detailTextLabel?.font = AppFont.bodyScaled

            return cell
        } else if indexPath.section == 4 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactKeyCell", for: indexPath)
            cell.textLabel?.font = AppFont.bodyScaled
            return cell
        } else if indexPath.section == 5 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactDataCell", for: indexPath)
            cell.textLabel?.font = AppFont.bodyScaled
            return cell
        } else if indexPath.section == 6 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactDeleteCell", for: indexPath)
            cell.textLabel?.font = AppFont.bodyScaled
            return cell
        }
        
        return UITableViewCell()
    }
    
    internal func tableViewPOBox(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        generateImpactFeedback()
        
        if indexPath.section == 1 {
            if let uploadedPackages = uploadedPackages, uploadedPackages.count > 0, indexPath.row < uploadedPackages.count {
                let package = uploadedPackages[indexPath.row]
                performSegue(withIdentifier: showCredentialDetailsSegue, sender: package)
            } else if SettingsBundleHelper.shared.savedEnvironment.canShowRegistration {
                performSegue(withIdentifier: showContactCredentialsSegue, sender: nil)
            }
        } else if indexPath.section == 4 {
            performSegue(withIdentifier: showKeyPairDetailsSegue, sender: nil)
        } else if indexPath.section == 5 {
            performSegue(withIdentifier: showAssociatedDataSegue, sender: nil)
        } else if indexPath.section == 6 {
            deleteContact()
        }
    }
    
    @objc func buttonTapped(sender : UIButton) {

        tableView.isScrollEnabled = true
        let dataView = sender.superview
        dataView?.removeFromSuperview()
    }
    
    override var editingInteractionConfiguration: UIEditingInteractionConfiguration {
        return .none
    }
}
