//
//  PasscodeTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import LocalAuthentication

class PasscodeTableViewController: UITableViewController {
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var PINOptionLabel: UILabel!
    
    @IBOutlet weak var biometricOptionLabel: UILabel!
    @IBOutlet weak var biometricOptionValue: UILabel!
    
    @IBOutlet weak var changePasscodeTableViewCell: UITableViewCell!
    @IBOutlet weak var deletePinTableViewCell: UITableViewCell!
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupView()
    }
    
    @IBAction func unwindToPasscode(segue: UIStoryboardSegue) {
        setupView()
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let context = LAContext()
    
    // MARK: Private Methods
    
    private func setupView() {
        PINOptionLabel?.text = DataStore.shared.hasPINEnabled ? "profile.pin.change".localized : "profile.pin.create".localized
        
        let isBiometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        
        if isBiometricAvailable, context.biometryType == .touchID {
            biometricOptionValue.text = "profile.pin.touchID".localized
        } else if isBiometricAvailable, context.biometryType == .faceID {
            biometricOptionValue.text = "profile.pin.faceID".localized
        } else {
            biometricOptionValue.text = "profile.pin".localized
        }
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
        //let accessibilityElements = [changePasscodeTableViewCell, deletePinTableViewCell]
        // setButtonAccessibilityTraits(for: accessibilityElements)
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPinOptions",
           let navigationController = segue.destination as? CustomNavigationController,
           let pinOptionsViewController = navigationController.viewControllers.first as? PinOptionsViewController {
            pinOptionsViewController.isSettingsScene = true
            pinOptionsViewController.mode = .create
        }
    }
    
}

extension PasscodeTableViewController {
    // ======================================================================
    // === UITableView ==============================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return DataStore.shared.hasPINEnabled ? 2 : 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return DataStore.shared.hasPINEnabled ? 2 : 1
        }
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        generateImpactFeedback()
        
        if indexPath.section == 0, indexPath.row == 0 {
            performSegue(withIdentifier: "showPinOptions", sender: nil)
        } else if indexPath.section == 0, indexPath.row == 1 {
            self.showConfirmation(title: "profile.pin.delete".localized, message: "profile.pin.deleteMessage".localized,
                                  actions: [("cred.delete.title".localized, IBMAlertActionStyle.destructive), ("button.title.cancel".localized, IBMAlertActionStyle.cancel)],
                                  completion: { index in
                if index == 0 {
                    DataStore.shared.userPIN = nil
                }
                
                self.setupView()
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.font = AppFont.bodyScaled
        cell.detailTextLabel?.font = AppFont.bodyScaled
    }
    
}
