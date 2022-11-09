//
//  WalletTableViewController+Registration.swift
//  Holder
//
//  Created by Gautham Velappan on 12/2/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

extension WalletTableViewController {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Methods
    
    internal func showNewRegistration(org: String? = nil) {
        performSegue(withIdentifier: presentNewRegistration, sender: org)
    }
    
    internal func readContactJSONFromFile(fileUrl: URL) -> [[String: Any]]? {
        do {
            let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
            return try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        } catch {
            return nil
        }
    }
    
    internal func getContactTuple(from json: [[String: Any]]) -> (Credential, Credential)? {
        let credentials = json.compactMap { Credential(value: $0) }
        
        guard let profileCredentials = credentials.filter({ $0.extendedCredentialSubject?.type == "profile" }).first,
              let idCredentials = credentials.filter({ $0.extendedCredentialSubject?.type == "id" }).first else {
                  return nil
              }
        
        return (profileCredentials, idCredentials)
    }
}
