//
//  ContactDetailsTableViewController+AssociatedData.swift
//  Holder
//
//  Created by John Martino on 2021-05-13.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import os.log

extension ContactDetailsTableViewController {
    
    private func fetchCOSFiles(for ordID: String, and holderID: String, with signature: String) {
        CosAllFilesForHolderService().getAllHolderCosFiles(forOrganizationID: ordID, holderID: holderID, signature: signature) { result in
            switch result {
            case .success(let json):
                guard let payload = json["payload"] as? [[[String: Any]]], !(payload.isEmpty) else {
                    return
                }
                
            case .failure(let error):
                os_log("[FAIL] - All Cos Files For Holder %{public}@",
                       log: OSLog.services,
                       type: .error,
                       error.localizedDescription)
            }
        }
        
    }
    
    private func parseFiles(for content: [[String : Any]]) -> [[String: Any]]? {
        let symmetricKey = self.contact?.profileCredential?.credentialSubject?.technical?.poBox?.symmetricKey ?? self.contact?.profileCredential?.credentialSubject?.technical?.symmetricKey
        
        guard let decodedIVData = symmetricKey?.iv?.base64DecodedData(),
              let decodedKeyData = symmetricKey?.value?.base64DecodedData() else {
            return nil
        }
        
        var filesForOrgServiceResult = [[String: Any]]()
        
        for var item in content {
            if let contentValue = item["content"] as? String,
               let contentData = contentValue.base64DecodedData() {
                
                if let decryptedData = try? AESCrypto().decrypt(data: contentData, key: decodedKeyData, iv: decodedIVData),
                   let jsonObject = try? JSONSerialization.jsonObject(with: decryptedData, options: []) as? [[String : Any]] {
                    
                    item["content"] = jsonObject
                    filesForOrgServiceResult.append(item)
                }
            }
        }
        
        return filesForOrgServiceResult
    }
    
    private func fetchAllFiles(for linkID: String, with passcode: String) {
        PostboxAllFilesForOrgService().getAllFiles(forLinkID: linkID, passcode: passcode) { result in
            switch result {
            case .success(let json):
                
                guard let payload = json["payload"] as? [String: Any], !(payload.isEmpty),
                      let contentDictArray = payload["attachments"] as? [[String : Any]],
                      let files = self.parseFiles(for: contentDictArray) else {
                    os_log("[FAIL] - Get All Files Local Mapping problem",
                           log: OSLog.services,
                           type: .error)
                    return
                }
                
            case .failure(let error):
                os_log("[FAIL] - All Files For Organization %{public}@",
                       log: OSLog.services,
                       type: .error,
                       error.localizedDescription)
            }
        }
    }
    
    func showAssociatedData() {
        
        let organizationId = (contact?.profilePackage?.credential?.credentialSubject?.rawDictionary?["orgId"] as? String) ?? String("nih") //Fallback to nih if the orgID is not available
        
        if let publicKey = contact?.associatedKey?.publickey {
            
            self.showActivityIndicator()
            let signature = getSignature() ?? ""
            var cosFilesForHolderServiceResult: [[[String: Any]]] = []
            var filesForOrgServiceResult: [[String: Any]] = []
            
            DispatchQueue.global().async { [weak self] in
                let group = DispatchGroup()
                group.enter()
                CosAllFilesForHolderService().getAllHolderCosFiles(forOrganizationID: organizationId, holderID: publicKey, signature: signature){ cosResult in
                    switch cosResult {
                    case .success(let json):
                        
                        guard let payload = json["payload"] as? [[[String: Any]]], !(payload.isEmpty)
                        else {
                            group.leave()
                            return
                        }
                        cosFilesForHolderServiceResult = payload
                        
                    case .failure(let error):
                        os_log("[FAIL] - All Cos Files For Holder %{public}@", log: OSLog.services, type: .error, error.localizedDescription)
                    }
                    group.leave()
                }
                
                if let requiredPasscode = self?.contact?.profilePackage?.credential?.credentialSubject?.technical?.poBox?.passcode,
                   let requiredLinkId = self?.contact?.profilePackage?.credential?.credentialSubject?.technical?.poBox?.linkId {
                    group.enter()
                    PostboxAllFilesForOrgService().getAllFiles(forLinkID: requiredLinkId, passcode: requiredPasscode) { poResult in
                        switch poResult {
                        case .success(let json):
                            
                            let symmetricKey = self?.contact?.profileCredential?.credentialSubject?.technical?.poBox?.symmetricKey ?? self?.contact?.profileCredential?.credentialSubject?.technical?.symmetricKey
                            
                            guard let payload = json["payload"] as? [String: Any], !(payload.isEmpty),
                                  let contentDictArray = payload["attachments"] as? [[String : Any]],
                                  let decodedIVData = symmetricKey?.iv?.base64DecodedData(),
                                  let decodedKeyData = symmetricKey?.value?.base64DecodedData()
                            else {
                                os_log("[FAIL] - Get All Files Local Mapping problem", log: OSLog.services, type: .error)
                                group.leave()
                                return
                            }
                            
                            for var item in contentDictArray {
                                if let contentValue = item["content"] as? String,
                                   let contentData = contentValue.base64DecodedData() {
                                    
                                    if let decryptedData = try? AESCrypto().decrypt(data: contentData, key: decodedKeyData, iv: decodedIVData),
                                       let jsonObject = try? JSONSerialization.jsonObject(with: decryptedData, options: []) as? [[String : Any]] {
                                        
                                        item["content"] = jsonObject
                                        filesForOrgServiceResult.append(item)
                                    }
                                }
                            }
                            
                        case .failure(let error):
                            os_log("[FAIL] - All Files For Organization %{public}@", log: OSLog.services, type: .error, error.localizedDescription)
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) { [weak self] in
                    self?.hideActivityIndicator()
                    if cosFilesForHolderServiceResult.isEmpty && filesForOrgServiceResult.isEmpty {
                        self?.show(associatedData: ["contact.nodata".localized])
                    } else {
                        self?.show(associatedData: [cosFilesForHolderServiceResult, filesForOrgServiceResult])
                    }
                }
            }
        }
    }
    
    private func show(associatedData rawDictionary: [Any]) {
        let associatedData = try? JSONSerialization.data(withJSONObject: rawDictionary, options: .prettyPrinted)
        performSegue(withIdentifier: showAssociatedDataSegue, sender: associatedData)
    }
}

private extension ContactDetailsTableViewController {
    
    func getSignature() -> String? {
        
        guard let privateKey = contact?.associatedKey?.publickey,
              let publicKey = contact?.associatedKey?.publickey else {
            return nil
        }
        
        let unsignedData = Data("{\"proof\":{\"creator\":\"\(publicKey)\"}}".utf8) as CFData
        let cryptographicKey = KeyGen.getCryptographicKey(for: privateKey)
        
        guard let requiredKey = cryptographicKey.secKey else {
            os_log("Private key generation error -- %{public}@",
                   log: OSLog.contactDetails,
                   type: .error,
                   cryptographicKey.error.debugDescription)
            return nil
        }
        
        var error: Unmanaged<CFError>?
        guard let signedData = SecKeyCreateSignature(requiredKey,
                                                     SecKeyAlgorithm.rsaSignatureMessagePSSSHA256,
                                                     unsignedData,
                                                     &error) else {
            os_log("Digital signature generation error -- %{public}@",
                   log: OSLog.contactDetails,
                   type: .error,
                   error.debugDescription)
            
            error?.release()
            return nil
        }
        
        error?.release()
        
        return (signedData as Data).base64EncodedString(options: [])
    }
    
}
