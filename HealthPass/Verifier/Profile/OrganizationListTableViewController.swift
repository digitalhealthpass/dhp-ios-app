//
//  OrganizationListTableViewController.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class OrganizationListTableViewController: UITableViewController {
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkNavigationItem()
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet var tableViewPlaceholder: UIView!
    
    // MARK: - IBAction
    
    @IBAction func onCancel(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindToScan", sender: nil)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showOrganizationDetails",
           let organizationDetailsTableViewController = segue.destination as? OrganizationDetailsTableViewController {
            organizationDetailsTableViewController.package = sender as? Package
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    var allOrganizations: [Package]?
    var activeOrganizations: [Package]?
    var expiredOrganizations: [Package]?
    
    var selectedOrganization: Package?
    
    // MARK: Private Methods
    
    private func updateView() {
        allOrganizations = DataStore.shared.allOrganization
        selectedOrganization = DataStore.shared.currentOrganization
        
        activeOrganizations = allOrganizations?.filter { !($0.credential?.isExpired ?? false) }
        expiredOrganizations = allOrganizations?.filter { $0.credential?.isExpired ?? false }
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
        
        if let allOrganizations = allOrganizations, !(allOrganizations.isEmpty) {
            self.tableView.backgroundView = nil
        } else {
            self.tableView.backgroundView = self.tableViewPlaceholder
        }
    }
    
    private func checkNavigationItem() {
        if !isMovingToParent {
            let cancelBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancel))
            self.navigationItem.leftBarButtonItem = cancelBarButtonItem
        }
    }
    
}

extension OrganizationListTableViewController {
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if let expiredOrganizations = expiredOrganizations, !(expiredOrganizations.isEmpty) {
            return 2
        }
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0, !(activeOrganizations?.isEmpty ?? true) {
            return "OrganizationList.header.title1".localized +  " (\(activeOrganizations?.count ?? 0))"
        } else if section == 1 {
            return "OrganizationList.header.title2".localized +  " (\(expiredOrganizations?.count ?? 0))"
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return activeOrganizations?.count ?? 0
        } else if section == 1 {
            return expiredOrganizations?.count ?? 0
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OrganizationListCellID", for: indexPath)
        
        var organization: Package?
        
        cell.accessoryView = nil
        
        if indexPath.section == 0 {
            organization = activeOrganizations?[indexPath.row]
            
            if let currentOrganization = DataStore.shared.currentOrganization,
               currentOrganization.credential?.id == organization?.credential?.id {
                let selectedLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 64, height: 24))
                selectedLabel.text = "OrganizationList.selected.label".localized
                
                selectedLabel.clipsToBounds = true
                selectedLabel.font = UIFont(name: AppFont.medium, size: 11)
                selectedLabel.textAlignment = .center
                selectedLabel.backgroundColor = UIColor.systemBlue
                selectedLabel.textColor = UIColor.white
                selectedLabel.layer.cornerRadius = 4.0
                
                cell.accessoryView = selectedLabel
                cell.accessoryType = .none
            } else {
                cell.accessoryType = .disclosureIndicator
            }
            
            cell.selectionStyle = .default
        } else if indexPath.section == 1 {
            organization = expiredOrganizations?[indexPath.row]
            cell.selectionStyle = .none
            cell.accessoryType = .none
        }
        
        let credentialSubjectDictionary = organization?.credential?.credentialSubject ?? [String: Any]()
        let schemaDictionary = organization?.schema?.schema ?? [String: Any]()
        
        let fields = SchemaParser().getVisibleFields(for: credentialSubjectDictionary, and: schemaDictionary)
        
        let titlePath = fields.filter { $0.path == "organization" }.first
        let organizationTitle = titlePath?.value as? String ?? String()
        let organizationTitleLabel = cell.viewWithTag(2) as? UILabel
        organizationTitleLabel?.text = titlePath?.value as? String
        
        //Initials or Image
        var initialValue = String()
        let organizationTitleComponents = organizationTitle.components(separatedBy: " ")
        if let first = organizationTitleComponents.first {
            initialValue = String(first.prefix(1))
        }
        if (organizationTitleComponents.count > 1) {
            let second = organizationTitleComponents[1]
            initialValue = String("\(initialValue)\(String(second.prefix(1)))")
        }

        let initialLabel = UILabel()
        initialLabel.frame.size = CGSize(width: 52.0, height: 52.0)
        initialLabel.font = UIFont(name: AppFont.regular, size: 24)
        initialLabel.textColor = .label
        initialLabel.text = initialValue
        initialLabel.textAlignment = .center
        initialLabel.backgroundColor = .secondarySystemBackground
        
        UIGraphicsBeginImageContext(initialLabel.frame.size)
        initialLabel.layer.render(in: UIGraphicsGetCurrentContext()!)
        let organizationImageView = cell.viewWithTag(1) as? UIImageView
        organizationImageView?.image = UIGraphicsGetImageFromCurrentImageContext()
        organizationImageView?.backgroundColor = .secondarySystemBackground
        UIGraphicsEndImageContext()

        let subTitlePath = fields.filter { $0.path == "verifierType" }.first
        let organizationSubTitleLabel = cell.viewWithTag(3) as? UILabel
        organizationSubTitleLabel?.text = subTitlePath?.value as? String
        
        let organizationDetailLabel = cell.viewWithTag(4) as? UILabel
        organizationDetailLabel?.text = nil
        let credentialExpired = organization?.credential?.isExpired ?? false
        if let expireDateString = organization?.credential?.expirationDate {
            let expString = credentialExpired ? "result.expiredDate".localized : "result.expiresDate".localized
            let expiryDate = Date.dateFromString(dateString: expireDateString)
            organizationDetailLabel?.text = String(format: "%@ %@", expString, Date.stringForDate(date: expiryDate, dateFormatPattern: .IBMDefault))
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0, let activeOrganizations = activeOrganizations, !(activeOrganizations.isEmpty) {
            let selectedOrganization = activeOrganizations[indexPath.row]
            performSegue(withIdentifier: "showOrganizationDetails", sender: selectedOrganization)
        } else if indexPath.section == 1, let expiredOrganizations = expiredOrganizations, !(expiredOrganizations.isEmpty) {
            let selectedOrganization = expiredOrganizations[indexPath.row]
            performSegue(withIdentifier: "showOrganizationDetails", sender: selectedOrganization)
        }
    }
}
