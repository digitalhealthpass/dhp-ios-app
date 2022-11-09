//
//  ResetTableViewController.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import VerificationEngine

class ResetTableViewController: UITableViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.navigationBar.sizeToFit()
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods
    
    private func getCacheSizeString() -> String {
        let allIssuer = DataStore.shared.allIssuer ?? []
        let allJWKSet = DataStore.shared.allJWKSet ?? []
        let allIssuerKey = DataStore.shared.allIssuerKey ?? []
        
        let allSchema = DataStore.shared.allSchema ?? []
        let allIssuerMetadata = DataStore.shared.allIssuerMetadata ?? []
        
        let allVerifierConfiguration = DataStore.shared.allVerifierConfiguration ?? []
        
        let byteCount = Int64(MemoryLayout<Issuer>.size * allIssuer.count) + Int64(MemoryLayout<JWKSet>.size * allJWKSet.count) + Int64(MemoryLayout<IssuerKey>.size * allIssuerKey.count) + Int64(MemoryLayout<Schema>.size * allSchema.count) + Int64(MemoryLayout<IssuerMetadata>.size * allIssuerMetadata.count) + Int64(MemoryLayout<VerifierConfiguration>.size * allVerifierConfiguration.count)
        
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
    
    private func resetCache(cell: UITableViewCell?) {
        self.showConfirmation(title: "profile.resetCache.title".localized, message: "profile.resetCache.message".localized,
                              actions: [("profile.reset.action".localized, IBMAlertActionStyle.destructive), ("button.title.cancel".localized, IBMAlertActionStyle.cancel)], completion: { index in
            if index == 0 {
                DataStore.shared.resetUserLogin()
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
            return String(format: "reset.cache.footer1".localized, getCacheSizeString())
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        generateImpactFeedback()
        
        let cell = tableView.cellForRow(at: indexPath)
        
        if indexPath.section == 0 && indexPath.row == 0 {
            resetCache(cell: cell)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.font = AppFont.bodyScaled
        cell.detailTextLabel?.font = AppFont.bodyScaled
    }
    
}
