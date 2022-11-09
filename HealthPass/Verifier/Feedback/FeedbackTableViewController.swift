//
//  FeedbackTableViewController.swift
//  Verifier
//
//  Created by Gautham Velappan on 3/4/22.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class FeedbackTableViewController: UITableViewController {
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        updateSettings()
    }

    // MARK: - IBOutlet
    
    @IBOutlet weak var soundFeedbackTitleLabel: UILabel!
    @IBOutlet weak var soundFeedbackSwitch: UISwitch!
    
    @IBOutlet weak var hapticFeedbackTitleLabel: UILabel!
    @IBOutlet weak var hapticFeedbackSwitch: UISwitch!

    // MARK: - @IBAction
    
    @IBAction func onSoundFeedbackSwitch(_ sender: Any) {
        DataStore.shared.soundFeedbackState = !DataStore.shared.soundFeedbackState
        updateSettings()
    }
    
    @IBAction func onHapticFeedbackSwitch(_ sender: Any) {
        DataStore.shared.hapticFeedbackState = !DataStore.shared.hapticFeedbackState
        updateSettings()
    }

    // MARK: Private Methods
    
    private func updateSettings() {
        soundFeedbackSwitch.isOn = DataStore.shared.soundFeedbackState
        hapticFeedbackSwitch.isOn = DataStore.shared.hapticFeedbackState
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }

    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

}
