//
//  DataCenterSelectionViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class DataCenterSelectionViewController: UITableViewController {
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        allRegions = EnvTarget.debugEnv
        selectedRegion = SettingsBundleHelper.shared.savedEnvironment
    }
    
    // MARK: - Private Variables
    
    private var allRegions = [EnvTarget]() {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    private var selectedRegion = SettingsBundleHelper.shared.savedEnvironment {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        if (selectedRegion != SettingsBundleHelper.shared.savedEnvironment) {
            
            DataStore.shared.resetUserLogin()
            DataStore.shared.resetCache()
#if VERIFIER
            DataStore.shared.resetOrganizations()
#endif
            
            
            SettingsBundleHelper.shared.savedEnvironment = selectedRegion
        }
        
        guard let parent = self.presentingViewController else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        if parent.isKind(of: LaunchViewController.self) {
            DataStore.shared.didSelectDataCenter = true
            performSegue(withIdentifier: "unwindToLaunch", sender: nil)
        } else {
            performSegue(withIdentifier: "unwindToProfile", sender: nil)
        }
    }
    
    // MARK: - Table View Delegates
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allRegions.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerLabel = UILabel(frame: CGRect(x: 20, y: 0, width: tableView.frame.size.width - 80, height: 40))
        headerLabel.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
        headerLabel.textAlignment = .center
        headerLabel.numberOfLines = 0
        headerLabel.isAccessibilityElement = true
        headerLabel.adjustsFontSizeToFitWidth = true
        headerLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
        headerLabel.sizeToFit()
        return headerLabel
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
#if VERIFIER
        return "env.title.verifier".localized
#endif
        
        return "env.title".localized
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RegionCell", for: indexPath)
        
        let region = allRegions[indexPath.row]
        
        cell.textLabel?.text = region.title
        cell.detailTextLabel?.text = region.subTitle
        cell.accessoryType = (selectedRegion == region) ? .checkmark : .none
        // Accessibility traits
        cell.isAccessibilityElement = true
        cell.accessibilityTraits = .button
        
        cell.textLabel?.font = AppFont.bodyScaled
        cell.detailTextLabel?.font = AppFont.caption1Scaled
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRegion = allRegions[indexPath.row]
    }
}
