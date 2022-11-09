//
//  WalletTableViewController+Reminders.swift
//  Holder
//
//  Created by Gautham Velappan on 12/2/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

extension WalletTableViewController {

    // IBM RTO Reminder sections
    internal func checkExistingConnections() {
        guard DataStore.shared.IBM_RTO_Reminder else {
            return
        }
        
        let filteredPackage = packageArray.filter({
            guard let type = $0.credential?.credentialSubject?["type"] as? String, DataStore.shared.IBM_RTO_CRED_TYPE_PROD.contains(type),
                  let schemaName = $0.schema?.name, DataStore.shared.IBM_RTO_SCHEMA_NAME_PROD.contains(schemaName),
                  let issuerName = $0.issuerMetadata?.name, DataStore.shared.IBM_RTO_ISSUER_NAME_PROD.contains(issuerName) else {
                      return false
                  }
            
            return true
        })
        
        guard !(filteredPackage.isEmpty) else {
            return
        }
        
        let filteredContacts = self.contactsArray.compactMap({ contact -> Contact? in
            if let contactOrganization = contact.idPackage?.credential?.credentialSubject?["organization"] as? String,
               contactOrganization == DataStore.shared.IBM_RTO_ORG_PROD {
                return contact
            }
            
            return nil
        })
        
        for contact in filteredContacts {
            guard let uploadedPackages = contact.uploadedPackages else {
                self.showReminderForExisting(contact)
                return
            }
            
            guard !(uploadedPackages.isEmpty) else {
                self.showReminderForExisting(contact)
                return
            }
        }
    }
    
    internal func handleNewCredential(_ package: Package) {
        guard let type = package.credential?.credentialSubject?["type"] as? String, DataStore.shared.IBM_RTO_CRED_TYPE_PROD.contains(type),
              let schemaName = package.schema?.name, DataStore.shared.IBM_RTO_SCHEMA_NAME_PROD.contains(schemaName),
              let issuerName = package.issuerMetadata?.name, DataStore.shared.IBM_RTO_ISSUER_NAME_PROD.contains(issuerName) else {
                  self.requestReview()
                  return
              }
        
        let filteredContacts = self.contactsArray.compactMap({ contact -> Contact? in
            if let contactOrganization = contact.idPackage?.credential?.credentialSubject?["organization"] as? String,
               contactOrganization == DataStore.shared.IBM_RTO_ORG_PROD {
                return contact
            }
            
            return nil
        })
        
        for contact in filteredContacts {
            guard let uploadedPackages = contact.uploadedPackages else {
                self.showReminderForNew(contact)
                return
            }
            
            guard !(uploadedPackages.isEmpty) else {
                self.showReminderForNew(contact)
                return
            }
        }
    }
        
    private func showReminderForExisting(_ contact: Contact) {
        showConfirmation(title: "wallet.share.ibmrto.title".localized,
                         message: "wallet.share.ibmrto.message2".localized,
                         actions: [ ("wallet.share.ibmrto.action.yes.share".localized, IBMAlertActionStyle.default),
                                    ("wallet.share.ibmrto.action.no".localized, IBMAlertActionStyle.destructive),
                                    ("wallet.share.ibmrto.action.later".localized, IBMAlertActionStyle.cancel) ]) { index in
            if index == 0 {
                self.performSegue(withIdentifier: self.contactDetails, sender: contact)
            } else if index == 1 {
                DataStore.shared.IBM_RTO_Reminder = false
            }
        }
    }
    
    private func showReminderForNew(_ contact: Contact) {
        self.showConfirmation(title: "wallet.share.ibmrto.title".localized,
                              message: "wallet.share.ibmrto.message1".localized,
                              actions: [ ("wallet.share.ibmrto.action.yes.share".localized, IBMAlertActionStyle.default),
                                         ("wallet.share.ibmrto.action.later".localized, IBMAlertActionStyle.cancel) ]) { index in
            if index == 0 {
                self.performSegue(withIdentifier: self.contactDetails, sender: contact)
            }
        }
    }

}
