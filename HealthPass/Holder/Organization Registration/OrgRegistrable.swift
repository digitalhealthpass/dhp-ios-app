//
//  OrgRegistratable.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

protocol OrgRegistrable: AnyObject {
    var contactTuple: (Credential, Credential)? { get set }
}

extension OrgRegistrable {
    var unwindToWalletSegue: String {
        "unwindToWallet"
    }
    
    func contactTuple(from json: [[String: Any]]) -> (Credential, Credential)? {
        let credentials = json.compactMap { Credential(value: $0) }
        
        guard let profileCredentials = credentials.filter({ $0.extendedCredentialSubject?.type == "profile" }).first,
              let idCredentials = credentials.filter({ $0.extendedCredentialSubject?.type == "id" }).first else {
            return nil
        }
        
        return (profileCredentials, idCredentials)
    }
}
