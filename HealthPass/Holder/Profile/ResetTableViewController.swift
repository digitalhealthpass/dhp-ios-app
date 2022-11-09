//
//  ResetTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import VerificationEngine

class ResetTableViewController: UITableViewController {
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.sizeToFit()
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods
    
    private func getCacheSizeString() -> String {
        let allSchema = DataStore.shared.allSchema ?? []
        let allIssuerMetadata = DataStore.shared.allIssuerMetadata ?? []
        
        let allIssuer = DataStore.shared.allIssuer ?? []
        let allJWKSet = DataStore.shared.allJWKSet ?? []
        let allIssuerKey = DataStore.shared.allIssuerKey ?? []
        
        let byteCount = Int64(MemoryLayout<Schema>.size * allSchema.count) +
        Int64(MemoryLayout<IssuerMetadata>.size * allIssuerMetadata.count) +
        Int64(MemoryLayout<Issuer>.size * allIssuer.count) +
        Int64(MemoryLayout<JWKSet>.size * allJWKSet.count) +
        Int64(MemoryLayout<IssuerKey>.size * allIssuerKey.count)
        
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        
        return bcf.string(fromByteCount: byteCount)
    }
    
    private func didFinishResetAction() {
        self.generateNotificationFeedback(.error)
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
    
    private func eraseCredentials() {
        self.showConfirmation(title: "profile.cards.eraseAll".localized,
                              message: "profile.cards.deleteAll".localized,
                              actions: [("cred.delete.title".localized, IBMAlertActionStyle.destructive), ("button.title.cancel".localized, IBMAlertActionStyle.cancel)], completion: { index in
            if index == 0 {
                DataStore.shared.deleteAllUserPackages() { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        NotificationCenter.default.post(name: ProfileTableViewController.RefreshKeychainIdentifier, object: nil)
                        self.didFinishResetAction()
                    }
                }
            }
        })
    }
    
    private func resetCache() {
        self.showConfirmation(title: "profile.cache.resetCache".localized,
                              message: "profile.cache.reset".localized,
                              actions: [("profile.reset.action".localized, IBMAlertActionStyle.destructive), ("button.title.cancel".localized, IBMAlertActionStyle.cancel)], completion: { index in
            if index == 0 {
                DataStore.shared.resetCache()
                self.didFinishResetAction()
            }
        })
    }
    
}

extension ResetTableViewController {
    
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return String(format: "profile.reset.footer0Formant".localized, "\(DataStore.shared.userPackages.count)", DataStore.shared.userPackages.count > 1 ? "s" : "")
        } else if section == 1 {
            return String(format: "profile.reset.footer1Formant".localized, "\(getCacheSizeString())")
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return 1
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        generateImpactFeedback()
        
        if indexPath.section == 0 {
            eraseCredentials()
        } else if indexPath.section == 1 {
            resetCache()
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.font = AppFont.bodyScaled
        cell.detailTextLabel?.font = AppFont.bodyScaled
    }
    
}
