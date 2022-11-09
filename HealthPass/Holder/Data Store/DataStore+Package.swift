//
//  DataStore.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import Alamofire
import SwiftCBOR
import VerifiableCredential

// MARK: - Credential and Schema management Extension

extension DataStore {
    
    func getPackage(for credentialId: String) -> Package? {
        guard let requiredPackage = userPackages.filter({ $0.credential?.id == credentialId }).first else {
            return nil
        }
        
        return requiredPackage
    }
    
    func getPackage(for jws: JWS) -> Package? {
        guard let requiredPackage = userPackages.filter({ $0.jws?.payloadString == jws.payloadString }).first else {
            return nil
        }
        
        return requiredPackage
    }
    
    func getPackage(for nbf: UInt64) -> Package? {
        guard let requiredPackage = userPackages.filter({ $0.jws?.payload?.nbf == nbf }).first else {
            return nil
        }
        
        return requiredPackage
    }

    func getDCCPackage(for certificateIdentifier: String) -> Package? {
        guard let requiredPackage = userPackages.filter({
            guard let cose = $0.cose,
                  let cwt = CWT(from: cose.payload),
                let identifier = cwt.euHealthCert?.vaccinations?.first?.certificateIdentifier ?? cwt.euHealthCert?.recovery?.first?.certificateIdentifier ?? cwt.euHealthCert?.tests?.first?.certificateIdentifier else {
                    return false
            }
            
            return certificateIdentifier == identifier
        }).first else {
            return nil
        }
        
        return requiredPackage
    }
    
    mutating func migratePackages(_ packages: [Package], completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        var filteredPackages = [Package]()
        if let allPackagesArray = data[SecureStoreKey.kPackages.rawValue] as? [[String: Any]] {
            filteredPackages = allPackagesArray.map { Package(value: $0) }
        }
        filteredPackages.append(contentsOf: packages)

        let filteredPackagesArray = filteredPackages.compactMap { $0.rawDictionary }
        data[SecureStoreKey.kPackages.rawValue] = filteredPackagesArray
        
        updateSecureStoreData(data: data, with: completion)
    }
    
    mutating func savePackage(_ package: Package, completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        
        var filteredPackages = [Package]()
        if let allPackagesArray = data[SecureStoreKey.kPackages.rawValue] as? [[String: Any]] {
            let userPackages = allPackagesArray.map { Package(value: $0) }
            filteredPackages = userPackages.filter {
                if package.verifiableObject?.type == .VC || package.verifiableObject?.type == .IDHP || package.verifiableObject?.type == .GHP,
                   $0.credential?.id != package.credential?.id {
                    return true
                } else if package.verifiableObject?.type == .SHC,
                          $0.verifiableObject?.jws?.payloadString != package.verifiableObject?.jws?.payloadString {
                    return true
                } else if package.verifiableObject?.type == .DCC,
                          $0.verifiableObject?.cose?.payload.asData() != package.verifiableObject?.cose?.payload.asData() {
                    return true
                }
                
                return false
            }
        }
        filteredPackages.append(package)
        
        let filteredPackagesArray = filteredPackages.compactMap { $0.rawDictionary }
        data[SecureStoreKey.kPackages.rawValue] = filteredPackagesArray
        
        updateSecureStoreData(data: data, with: completion)
    }
    
    mutating func savePackages(_ packages: [Package], completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        
        var filteredPackages = [Package]()
        if let allPackagesArray = data[SecureStoreKey.kPackages.rawValue] as? [[String: Any]] {
            let userPackages = allPackagesArray.map { Package(value: $0) }
            packages.forEach { package in
                filteredPackages = userPackages.filter {
                    if package.verifiableObject?.type == .VC || package.verifiableObject?.type == .IDHP || package.verifiableObject?.type == .GHP,
                       $0.credential?.id != package.credential?.id {
                        return true
                    } else if package.verifiableObject?.type == .SHC,
                              $0.verifiableObject?.jws?.payloadString != package.verifiableObject?.jws?.payloadString {
                        return true
                    } else if package.verifiableObject?.type == .DCC,
                              $0.verifiableObject?.cose?.payload.asData() != package.verifiableObject?.cose?.payload.asData() {
                        return true
                    }
                    
                    return false
                }
            }
            filteredPackages = userPackages
        }
        filteredPackages.append(contentsOf: packages)
        
        let filteredPackagesArray = filteredPackages.compactMap { $0.rawDictionary }
        data[SecureStoreKey.kPackages.rawValue] = filteredPackagesArray
        
        updateSecureStoreData(data: data, with: completion)
    }

    mutating func deletePackage(_ package: Package, completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        
        var filteredPackages = [Package]()
        if let allPackagesArray = data[SecureStoreKey.kPackages.rawValue] as? [[String: Any]] {
            let userPackages = allPackagesArray.map { Package(value: $0) }
            filteredPackages = userPackages.filter {
                if package.verifiableObject?.type == .VC || package.verifiableObject?.type == .IDHP || package.verifiableObject?.type == .GHP,
                   $0.credential?.id != package.credential?.id {
                    return true
                } else if package.verifiableObject?.type == .SHC,
                          $0.verifiableObject?.jws?.payloadString != package.verifiableObject?.jws?.payloadString {
                    return true
                } else if package.verifiableObject?.type == .DCC,
                          $0.verifiableObject?.cose?.payload.asData() != package.verifiableObject?.cose?.payload.asData() {
                    return true
                }
                
                return false
            }
        }
        
        let filteredPackagesArray = filteredPackages.compactMap { $0.rawDictionary }
        data[SecureStoreKey.kPackages.rawValue] = filteredPackagesArray
        
        updateSecureStoreData(data: data, with: completion)
    }
    
    mutating func deleteAllUserPackages(completion: ((Result<Bool>) -> Void)? = nil) {
        var data = getSecureStoreData()
        data[SecureStoreKey.kPackages.rawValue] = [[String : Any]]()
        
        updateSecureStoreData(data: data, with: completion)
    }
    
}
