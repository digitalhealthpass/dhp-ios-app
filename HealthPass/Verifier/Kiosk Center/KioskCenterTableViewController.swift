//
//  KioskCenterTableViewController.swift
//  Verifier
//
//  Created by Gautham Velappan on 1/19/22.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class KioskCenterTableViewController: UITableViewController {
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        updateSettings()
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var kioskModeTitleLabel: UILabel!
    @IBOutlet weak var kioskModeSwitch: UISwitch!
    
    @IBOutlet weak var frontCameraTitleLabel: UILabel!
    @IBOutlet weak var frontCameraSwitch: UISwitch!

    @IBOutlet weak var autoDismissTitleLabel: UILabel!
    @IBOutlet weak var autoDismissSwitch: UISwitch!
    
    @IBOutlet weak var dismissDurationTitleLabel: UILabel!
    @IBOutlet weak var dismissDurationSubTitleLabel: UILabel!
    
    // MARK: - @IBAction
    
    @IBAction func onKioskModeSwitch(_ sender: Any) {
        DataStore.shared.kioskModeState = !DataStore.shared.kioskModeState
        updateSettings()
    }
    
    @IBAction func onDefaultCameraSwitch(_ sender: Any) {
        DataStore.shared.frontCameraState = !DataStore.shared.frontCameraState
        updateSettings()
    }

    @IBAction func onAutoDismissSwitch(_ sender: Any) {
        DataStore.shared.alwaysDismissState = !DataStore.shared.alwaysDismissState
        updateSettings()
    }
    
    // MARK: Private Methods
    
    private func updateSettings() {
        kioskModeSwitch.isOn = DataStore.shared.kioskModeState
        frontCameraSwitch.isOn = DataStore.shared.frontCameraState
        autoDismissSwitch.isOn = DataStore.shared.alwaysDismissState
        dismissDurationSubTitleLabel.text = String("\(DataStore.shared.alwaysDismissDuration) seconds")
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
    
    private func onDismissDuration() {
        self.showConfirmation(title: "Auto Dismiss Duration", message: "",
                             actions: [("3 seconds", IBMAlertActionStyle.default),
                                       ("5 seconds", IBMAlertActionStyle.default),
                                       ("10 seconds", IBMAlertActionStyle.default)],
                             completion: { index in
            if index == 0 {
                DataStore.shared.alwaysDismissDuration = 3
            } else if index == 1 {
                DataStore.shared.alwaysDismissDuration = 5
            } else if index == 2 {
                DataStore.shared.alwaysDismissDuration = 10
            }
            
            self.updateSettings()
        })
    }
    
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return DataStore.shared.kioskModeState ? 4 : 1
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            onDismissDuration()
        }
    }
    
}
