//
//  Contact.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit

enum ContactInfoType {
    case download
    case upload
    case both
    
    case pobox
    
    case unknown
}

struct Contact {
    var profilePackage: Package?
    var idPackage: Package?
    
    var downloadedCredentialIDs: [String]?
    
    var rawDictionary: [String: Any]?
    var rawString: Any?
    
    init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        if let profileDictionary = value["profilePackage"] as? [String: Any] {
            profilePackage = Package(value: profileDictionary)
        }
        if let idDictionary = value["idPackage"] as? [String: Any] {
            idPackage = Package(value: idDictionary)
        }
        
        downloadedCredentialIDs = value["downloadedCredentialIDs"] as? [String]
    }
}

extension Contact {
    
    var profileCredential: Credential? {
        return profilePackage?.credential
    }
    
    var idCredential: Credential? {
        return idPackage?.credential
    }
    
    var contactInfoType: ContactInfoType {
        let profileCredentialSubject = profileCredential?.extendedCredentialSubject
        
        if (profileCredentialSubject?.technical?.download != nil) && (profileCredentialSubject?.technical?.upload != nil) {
            return .both
        } else if (profileCredentialSubject?.technical?.download != nil) {
            return .download
        } else if (profileCredentialSubject?.technical?.upload != nil) {
            return .upload
        } else if let _ = profileCredentialSubject?.consentInfo {
            return .pobox
        }
        
        return .unknown
    }

    var associatedKey: AsymmetricKeyPair? {
        let contactKey = idPackage?.credential?.extendedCredentialSubject?.id
        let userKeys = DataStore.shared.userKeyPairs
        
        let associatedKey = userKeys.filter { $0.publickey == contactKey }.first
        return associatedKey
    }
    
    var associatedUploadDetails: ContactUploadDetails? {
        let contactid = idPackage?.credential?.id
        let contactUploadDetails = DataStore.shared.contactUploadDetails

        let associatedUploadDetails = contactUploadDetails.filter { $0.contactID == contactid }.first
        return associatedUploadDetails
    }
    
    var uploadedPackages: [Package]? {
        let associatedCredentialIds = self.associatedUploadDetails?.associatedCredentials ?? [String]()
        let userPackages = DataStore.shared.userPackages

        let uploadedPackages = userPackages.filter({ (package: Package) -> Bool in
            return associatedCredentialIds.contains(where: { (id: String) -> Bool in
                if package.type == .IDHP || package.type == .GHP || package.type == .VC {
                    return package.credential?.id == id
                } else if package.type == .SHC {
                    return package.jws?.payload?.nbf == UInt64(id)
                } else if package.type == .DCC {
                    guard let cose = package.cose,
                          let cwt = CWT(from: cose.payload),
                          let certificateIdentifier = cwt.euHealthCert?.vaccinations?.first?.certificateIdentifier ?? cwt.euHealthCert?.recovery?.first?.certificateIdentifier ?? cwt.euHealthCert?.tests?.first?.certificateIdentifier else {
                              return false
                          }
                    
                    return certificateIdentifier == id
                }
                
                return false
            })
        })
        
        return uploadedPackages
    }
    
    var downloadedPackages: [Package]? {
        let downloadedCredentialIDs = self.downloadedCredentialIDs ?? [String]()
        let userPackages = DataStore.shared.userPackages

        let downloadedPackages = userPackages.filter({ (package: Package) -> Bool in
            return downloadedCredentialIDs.contains(where: { (credentialid: String) -> Bool in
                return package.credential?.id == credentialid
            })
        })
        
        return downloadedPackages
    }

    func checkContactCompatability() -> Bool {
        guard let credentialSubject = idPackage?.credential?.extendedCredentialSubject else {
            return false
        }
        
        guard credentialSubject.type == String("id") else {
            return false
        }
        
        guard let publicKey = credentialSubject.id else {
            return false
        }
        
        let userPublicKeys = DataStore.shared.userKeyPairs.compactMap { $0.publickey }
        
        return userPublicKeys.contains(publicKey)
    }
    
    func checkContactDuplication() -> Bool {
        guard let credentialSubject = idPackage?.credential?.extendedCredentialSubject else {
            return true
        }
        
        guard credentialSubject.type == String("id") else {
            return true
        }

        guard let publicKey = credentialSubject.id else {
            return true
        }

        let userContactsKeys = DataStore.shared.userContacts.compactMap { $0.idPackage?.credential?.extendedCredentialSubject?.id }

        return userContactsKeys.contains(publicKey)
    }
    
    func getOrganizationId() -> String {
        return (profileCredential?.extendedCredentialSubject?.rawDictionary?["orgId"] as? String) ?? String("nih")
    }

}
