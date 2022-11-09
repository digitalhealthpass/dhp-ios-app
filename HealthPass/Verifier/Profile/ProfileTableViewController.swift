//
//  ProfileTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import MobileCoreServices

class ProfileTableViewController: UITableViewController {
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        updateSettings()
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var currentOrganizationTitleLabel: UILabel!
    @IBOutlet weak var currentOrganizationValueLabel: UILabel!
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var envLabel: UILabel!
    @IBOutlet weak var languageLabel: UILabel!
    
    @IBAction func unwindToProfile(segue: UIStoryboardSegue) {
        updateSettings()
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private let unwindToLaunchSegue = "unwindToLaunch"
    private let showPrivacyPolicySegue = "showPrivacyPolicy"
    private let showTermsConditionsSegue = "showTermsConditions"
    private let showDataCenter = "showDataCenter"
    private let showThirdPartyLicenses = "showThirdPartyLicenses"
    
    // MARK: Private Methods
    
    private func updateSettings() {
        currentOrganizationTitleLabel.text = "Profile.currentOrganization.title".localized
        
        if let selectedOrganization = DataStore.shared.currentOrganization {
            let credentialSubjectDictionary = selectedOrganization.credential?.credentialSubject ?? [String: Any]()
            let schemaDictionary = selectedOrganization.schema?.schema ?? [String: Any]()
            
            let fields = SchemaParser().getVisibleFields(for: credentialSubjectDictionary, and: schemaDictionary)
            let titlePath = fields.filter { $0.path == "organization" }.first
            currentOrganizationValueLabel.text = titlePath?.value as? String
        } else {
            currentOrganizationValueLabel.text = nil
        }
        
        
        versionLabel?.text = String(format: "%@", Bundle.main.appVersionNumber ?? "")
        envLabel?.text = SettingsBundleHelper.shared.savedEnvironment.title
        languageLabel?.text = Locale.current.languageCode
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
    
}

extension ProfileTableViewController {
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        generateImpactFeedback()
        
        if indexPath.section == 4 {
            if indexPath.row == 0 {
                performSegue(withIdentifier: showTermsConditionsSegue, sender: nil)
            } else if indexPath.row == 1 {
                performSegue(withIdentifier: showPrivacyPolicySegue, sender: nil)
            } else if indexPath.row == 2 {
                performSegue(withIdentifier: showThirdPartyLicenses, sender: nil)
            }
        } else if indexPath.section == 5 {
            if indexPath.row == 0 {
                performSegue(withIdentifier: showDataCenter, sender: nil)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.font = AppFont.bodyScaled
        cell.detailTextLabel?.font = AppFont.bodyScaled
    }
    
}
