//
//  ResultViewController+Display.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import OSLog
import SwiftCBOR
import VerifiableCredential
import VerificationEngine

extension ResultViewController {
    
    internal func prepareDisplayFields(showAll: Bool = false) {
        let credentialType = verifiableObject?.type ?? self.type
        
        if showAll {
            let allDisplayFields = DisplayService().getAllDisplayFields(for: self.verifiableObject) ?? [DisplayField]()
            self.displayFields = DisplayService().scanObfuscation(for: allDisplayFields, with: verifiableObject)
        } else {
            guard let displayFields = DisplayService().getDisplayConfig(for: credentialType), !(displayFields.isEmpty) else {
                let allDisplayFields = DisplayService().getAllDisplayFields(for: self.verifiableObject) ?? [DisplayField]()
                self.displayFields = DisplayService().scanObfuscation(for: allDisplayFields, with: verifiableObject)
                return
            }
            
            guard let parseDisplayFields = self.parseDisplayFields(displayFields: displayFields), !(parseDisplayFields.isEmpty) else {
                let allDisplayFields = DisplayService().getAllDisplayFields(for: self.verifiableObject) ?? [DisplayField]()
                self.displayFields = DisplayService().scanObfuscation(for: allDisplayFields, with: verifiableObject)
                return
            }
            
            self.displayFields = DisplayService().scanObfuscation(for: parseDisplayFields, with: verifiableObject)
        }
    }
    
    private func parseDisplayFields(displayFields: [DisplayField]) -> [DisplayField]? {
        self.displayFields = [DisplayField]()
        
        guard let requiredPayload = verifiableObject?.payload else {
            return nil
        }
        
        displayFields.forEach { displayField in
            let path = displayField.field
            os_log("parseDisplayFields - field - %{public}@", log: OSLog.resultViewControllerOSLog, type: .info, path)
            
            if let json = requiredPayload as? [String: Any], let value = self.getValue(at: path, for: json) {
                var requiredDisplayField = displayField
                requiredDisplayField.value = value
                
                self.displayFields.append(requiredDisplayField)
            } else if let cbor = requiredPayload as? [CBOR: CBOR], let value = self.getValue(at: path, for: cbor) {
                var requiredDisplayField = displayField
                requiredDisplayField.value = value
                
                self.displayFields.append(requiredDisplayField)
            }
        }
        
        return (self.displayFields.sorted(by: { $0.field < $1.field }))
    }
    
    internal func prepareDisplayFields(for specificationConfiguration: SpecificationConfiguration?, showAll: Bool = false) {
        if showAll {
            self.displayFields = DisplayService().getAllDisplayFields(for: self.verifiableObject) ?? [DisplayField]()
            self.displayFields = DisplayService().scanObfuscation(for: self.displayFields, with: verifiableObject)
        } else {
            guard let displayFields = DisplayService().getDisplayConfig(for: specificationConfiguration), !(displayFields.isEmpty) else {
                self.displayFields = DisplayService().getAllDisplayFields(for: self.verifiableObject) ?? [DisplayField]()
                self.displayFields = DisplayService().scanObfuscation(for: self.displayFields, with: verifiableObject)
                return
            }
            
            guard let parseDisplayFields = self.parseDisplayFields(displayFields: displayFields), !(parseDisplayFields.isEmpty) else {
                self.displayFields = DisplayService().getAllDisplayFields(for: self.verifiableObject) ?? [DisplayField]()
                self.displayFields = DisplayService().scanObfuscation(for: self.displayFields, with: verifiableObject)
                return
            }
            
            self.displayFields = DisplayService().scanObfuscation(for: parseDisplayFields, with: verifiableObject)
        }
    }

}

extension ResultViewController {
    
    internal func fetchIssuerDetails(completion: @escaping () -> Void) {
        guard let type = verifiableObject?.type else {
            completion()
            return
        }
        
        if type == .IDHP || type == .GHP || type == .VC {
            fetchIssuerMetadata(completion: completion)
        } else if type == .SHC {
            fetchSmartHealthIssuer(completion: completion)
        } else if type == .DCC {
            fetchEUDCCIssuer(completion: completion)
        }
    }
    
    private func fetchIssuerMetadata(completion: @escaping () -> Void) {
        guard let issuerId = verifiableObject?.credential?.issuer else {
            issuerDetails = nil
            completion()
            return
        }
        
        if let issuerMetadata = DataStore.shared.getIssuerMetadata(for: issuerId) {
            issuerDetails = issuerMetadata.name
            completion()
            return
        }
        
        IssuerService().getIssuerMetadata(issuerId: issuerId) { result in
            switch result {
            case .success(let json):
                guard let payload = json["payload"] as? [String : Any], !(payload.isEmpty) else {
                    self.issuerDetails = nil
                    completion()
                    return
                }
                
                let issuerMetadata = IssuerMetadata(value: payload)
                DataStore.shared.addNewIssuerMetadata(issuerMetadata: issuerMetadata)
                self.issuerDetails = issuerMetadata.name
                completion()
                
            case .failure:
                self.issuerDetails = nil
                completion()
            }
            
        }
    }
    
    private func fetchSmartHealthIssuer(completion: @escaping () -> Void) {
        guard let issuerIdentifier = verifiableObject?.jws?.payload?.iss else {
            self.issuerDetails = nil
            completion()
            return
        }
        
        guard let jwkSet = DataStore.shared.getJWKSet(for: issuerIdentifier), !(jwkSet.isEmpty) else {
            self.issuerDetails = nil
            completion()
            return
        }
        
        let issuerNames = jwkSet.compactMap({ $0.name })
        self.issuerDetails = issuerNames.first
        completion()
    }
    
    private func fetchEUDCCIssuer(completion: @escaping () -> Void) {
        guard let cose = verifiableObject?.cose,
              let cwt = CWT(from: cose.payload),
              let iss = cwt.iss else {
                  self.issuerDetails = nil
                  completion()
                  return
              }
        
        self.issuerDetails = Locale.current.localizedString(forRegionCode: iss) ?? iss
        completion()
    }
    
}
