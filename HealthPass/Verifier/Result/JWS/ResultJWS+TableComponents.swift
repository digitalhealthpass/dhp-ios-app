//
//  ResultJWS+TableComponents.swift
//  Verifier
//
//  Created by Gautham Velappan on 6/13/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

extension ResultJWSTableViewController {
    
    // ======================================================================
    // === UITableView ======================================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return  2
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0  {
            return fetchCredentialOverallTableViewCell(for: indexPath)
        } else if indexPath.section == 1 {
            return fetchCredentialStatusTableViewCell(for: indexPath)
        }
        
        return UITableViewCell()
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(40.0)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = UIFont(name: AppFont.bold, size: 20)
        header.textLabel?.textColor = UIColor.label
        header.textLabel?.text = header.textLabel?.text?.capitalized
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension ResultJWSTableViewController {
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods
    
    private func fetchCredentialOverallTableViewCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CredentialOverallTableViewCell", for: indexPath)
        
        var textLabelString = "result.loading".localized
        var statusImage = loadingImage
        
        var statusTintColor = UIColor.label
        
        if let validityCheck = validityCheck {
            let isValid = validityCheck.0
            statusImage = isValid ? successImage : failImage
            statusTintColor = isValid ? .systemGreen : .systemRed
            textLabelString = isValid ? "result.validCredential".localized : "result.invalidCredential".localized
        }
        
        let statusImageView = cell.viewWithTag(1) as? UIImageView
        statusImageView?.image = statusImage
        statusImageView?.tintColor = statusTintColor
        
        let textLabel = cell.viewWithTag(2) as? UILabel
        textLabel?.text = textLabelString
        textLabel?.textColor = statusTintColor
        
        return cell
    }
    
    private func fetchCredentialStatusTableViewCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CredentialStatusTableViewCell", for: indexPath)
        
        var textLabelString = "result.loading".localized
        var detailTextLabelString: String?
        var statusImage = loadingImage
        
        var statusTintColor = UIColor.label
        
        if indexPath.row == 0, let signatureCheck = signatureCheck {
            if let isValidSignature = signatureCheck.0 {
                statusImage = isValidSignature ? successImage : failImage
                statusTintColor = isValidSignature ? .systemGreen : .systemRed
                textLabelString = isValidSignature ? "result.validSignature".localized : "result.invalidSignature".localized
            } else {
                statusImage = warningImage
                statusTintColor = .systemYellow
                textLabelString = "result.signatureVerificationSkipped".localized
            }
            
            detailTextLabelString = signatureCheck.1
        } else if indexPath.row == 1, let expiryCheck = expiryCheck {
            if let isExpired = expiryCheck.0 {
                statusImage = isExpired ? failImage : successImage
                statusTintColor = isExpired ? .systemRed : .systemGreen
                textLabelString = isExpired ? "result.expired".localized : "result.notExpired".localized
            } else {
                statusImage = warningImage
                statusTintColor = .systemYellow
                textLabelString = "result.expirationVerificationSkipped".localized
            }
            
            detailTextLabelString = expiryCheck.1
        }
        
        let textLabel = cell.viewWithTag(1) as? UILabel
        textLabel?.text = textLabelString
        
        let detailTextLabel = cell.viewWithTag(2) as? UILabel
        detailTextLabel?.text = detailTextLabelString
        
        let statusImageView = cell.viewWithTag(3) as? UIImageView
        statusImageView?.image = statusImage
        statusImageView?.tintColor = statusTintColor
        
        return cell
    }
    
}
