//
//  ScanViewController+Organization.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit
import VerifiableCredential

extension ScanViewController {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Methods
    
    @discardableResult
    internal func checkOrganization() -> Bool {
        guard let _ = DataStore.shared.currentOrganization else {
            let title = "ScanView.no.organization.title".localized
            let message = "ScanView.no.organization.message".localized
            let action = [("button.title.ok".localized, IBMAlertActionStyle.cancel)]
            
            self.scannerView.stopScanner()
            self.showConfirmation(title: title, message: message, actions: action) { index in
                self.scannerView.startScanner()
            }
            
            return false
        }
        
        return true
    }
    
    @discardableResult
    internal func checkOrganizationValidity() -> Bool {
        if currentOrganization?.credential?.isExpired ?? false {
            
            DataStore.shared.currentOrganizationDictionary = nil
            self.currentOrganization = nil
            
            let activeOrganizations = DataStore.shared.allOrganization?.filter { !($0.credential?.isExpired ?? false) } ?? [Package]()
            
            let title = "ScanView.organization.expired.title".localized
            let message = activeOrganizations.isEmpty ? "ScanView.organization.expired.message1".localized : "ScanView.organization.expired.message2".localized
            let action = activeOrganizations.isEmpty ? [("ScanView.organization.expired.button1".localized, IBMAlertActionStyle.cancel)] : [("ScanView.organization.expired.button1".localized, IBMAlertActionStyle.cancel), ("ScanView.organization.expired.button2".localized, IBMAlertActionStyle.default)]
            
            scannerView.stopScanner()
            self.showConfirmation(title: title, message: message, actions: action) { index in
                self.scannerView.startScanner()
                if index == 1 {
                    self.performSegue(withIdentifier: "showOrganizationList", sender: nil)
                }
            }
            
            return false
        }
        
        return true
    }
    
    internal func handleOrganizationCredential(credential: Credential) {
        scannerView.stopScanner()
        
        self.performSegue(withIdentifier: showOrganizationDetailsSegue, sender: credential)
    }
    
    internal func showOrganizationFooter(_ currentOrganization: Package) {
        guard checkOrganizationValidity() else {
            return
        }
        
        organizationView.isHidden = false
        statusLabel.isHidden = true
        
        let credentialSubjectDictionary = currentOrganization.credential?.credentialSubject ?? [String: Any]()
        let schemaDictionary = currentOrganization.schema?.schema ?? [String: Any]()
        
        let fields = SchemaParser().getVisibleFields(for: credentialSubjectDictionary, and: schemaDictionary)
        
        let titlePath = fields.filter { $0.path == "organization" }.first
        let organizationTitleValue = titlePath?.value as? String ?? String()
        organizationTitle.text = organizationTitleValue
        
        //Initials or Image
        var initialValue = String()
        let organizationTitleComponents = organizationTitleValue.components(separatedBy: " ")
        if let first = organizationTitleComponents.first {
            initialValue = String(first.prefix(1))
        }
        if (organizationTitleComponents.count > 1) {
            let second = organizationTitleComponents[1]
            initialValue = String("\(initialValue)\(String(second.prefix(1)))")
        }
        
        let initialLabel = UILabel()
        initialLabel.frame.size = CGSize(width: 52.0, height: 52.0)
        initialLabel.font = UIFont(name: AppFont.regular, size: 24)
        initialLabel.textColor = .label
        initialLabel.text = initialValue
        initialLabel.textAlignment = .center
        initialLabel.backgroundColor = .secondarySystemBackground
        
        UIGraphicsBeginImageContext(initialLabel.frame.size)
        initialLabel.layer.render(in: UIGraphicsGetCurrentContext()!)
        organizationImage?.image = UIGraphicsGetImageFromCurrentImageContext()
        organizationImage?.backgroundColor = .secondarySystemBackground
        UIGraphicsEndImageContext()
        
        let subTitlePath = fields.filter { $0.path == "verifierType" }.first
        organizationDetail.text = subTitlePath?.value as? String
        
        let credentialExpired = currentOrganization.credential?.isExpired ?? false
        if let expireDateString = currentOrganization.credential?.expirationDate {
            let expString = credentialExpired ? "ScanView.result.expiredDate".localized : "ScanView.result.expiresDate".localized
            let expiryDate = Date.dateFromString(dateString: expireDateString)
            organizationExpiration?.text = String(format: "%@ %@", expString, Date.stringForDate(date: expiryDate, dateFormatPattern: .IBMDefault))
        }
    }
    
    internal func showSelectOrganization() {
        let title = "ScanView.select.organization.title".localized
        let message = "ScanView.select.organization.message".localized
        let action = [("button.title.cancel".localized, IBMAlertActionStyle.cancel), ("ScanView.select.organization.button".localized, IBMAlertActionStyle.default)]
        
        self.showConfirmation(title: title,
                              message: message,
                              actions: action,
                              completion: { index in
            self.scannerView.startScanner()
            if index == 1 {
                self.performSegue(withIdentifier: "showOrganizationList", sender: nil)
            }
        }, presentCompletion: {
            self.scannerView.stopScanner()
        })
    }
    
}
