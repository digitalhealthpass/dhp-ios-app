//
//  ContactDownloadUtil.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

class ContactDownloadUtil {
    
    init(delegate: ContactDownloadTableViewControllerDelegate? = nil, constructedCredential: Credential) {
        self.delegate = delegate
        self.constructedCredential = constructedCredential
        
        fetchSchema(for: constructedCredential)
        fetchIssuerMetadata(for: constructedCredential)
    }
    
    private weak var delegate: ContactDownloadTableViewControllerDelegate?
    
    private var constructedPackage: Package?
    
    private var constructedCredential: Credential
    
    private var constructedSchema: Schema? {
        didSet {
            didFetchSchema = (constructedSchema != nil)
        }
    }
    
    private var constructedIssuerMetadata: IssuerMetadata? {
        didSet {
            didFetchIssuerMetadata = (constructedIssuerMetadata != nil)
        }
    }
    
    private var didFetchSchema: Bool? {
        didSet {
            constructPackage()
        }
    }
    
    private var didFetchIssuerMetadata: Bool? {
        didSet {
            constructPackage()
        }
    }
    
    private func constructPackage() {
        guard let didFetchSchema = didFetchSchema, didFetchSchema,
              (didFetchIssuerMetadata != nil) else { return }
        
        var packageDictionary = [String: Any]()
        
        packageDictionary["credential"] = constructedCredential.rawString
        packageDictionary["schema"] = constructedSchema?.rawString
        packageDictionary["issuerMetadata"] = constructedIssuerMetadata?.rawString
        
        let package = Package(value: packageDictionary)
        constructedPackage = package
        
        delegate?.didFinishVerification(for: constructedCredential, with: constructedPackage)
    }
    
    private func fetchSchema(for credential: Credential) {
        guard let schemaId = credential.credentialSchema?.id else {
            self.constructedSchema = nil
            return
        }
        
        //Check local cache
        guard !checkSchemaCache(for: credential) else { return }
        
        SchemaService().getSchema(schemaId: schemaId) { result in
            
            switch result {
            case let .success(data):
                guard let payload = data["payload"] as? [String : Any], !(payload.isEmpty) else {
                    self.constructedSchema = nil
                    return
                }
                
                self.handleSchemaResponse(payload)
                
            case let .failure(error):
                self.constructedSchema = nil
                
                self.delegate?.didFailVerification(for: self.constructedCredential, with: error)
            }
        }
    }
    
    private func checkSchemaCache(for credential: Credential) -> Bool {
        guard let schema = DataStore.shared.getSchema(for: credential) else {
            return false
        }
        
        self.constructedSchema = schema
        
        return true
    }
    
    private func handleSchemaResponse(_ schemaPayload: [String : Any]) {
        let schema = Schema(value: schemaPayload)
        DataStore.shared.addNewSchema(schema: schema)
        
        self.constructedSchema = schema
    }
    
    private func fetchIssuerMetadata(for credential: Credential) {
        guard let issuerId = credential.issuer else {
            self.constructedIssuerMetadata = nil
            return
        }
        
        //Check local cache
        guard !checkIssuerMetadataCache(for: credential) else { return }
        
        IssuerService().getIssuerMetadata(issuerId: issuerId) { result in
            switch result {
            case let .success(data):
                guard let payload = data["payload"] as? [String : Any], !(payload.isEmpty) else {
                    return
                }
                
                self.handleIssuerMetadataResponse(payload)
                
            case .failure:
                self.constructedIssuerMetadata = nil
            }
        }
    }
    
    private func checkIssuerMetadataCache(for credential: Credential) -> Bool {
        guard let issuerMetadata = DataStore.shared.getIssuerMetadata(for: credential) else {
            return false
        }
        
        self.constructedIssuerMetadata = issuerMetadata
        
        return true
    }
    
    private func handleIssuerMetadataResponse(_ issuerMetadataPayload: [String : Any]) {
        let issuerMetadata = IssuerMetadata(value: issuerMetadataPayload)
        DataStore.shared.addNewIssuerMetadata(issuerMetadata: issuerMetadata)
        
        self.constructedIssuerMetadata = issuerMetadata
    }
    
}
