//
//  SnapshotViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class SnapshotViewController: UIViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        appNameLabel?.font = AppFont.title1Scaled

        animateView()
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var stackView: UIStackView?

    @IBOutlet weak var logoImageView: UIImageView?
    @IBOutlet weak var appNameLabel: UILabel?
    @IBOutlet weak var addWalletItemButton: UIButton?

    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods
    
    private func defaultView() {
        stackView?.isHidden = false
        stackView?.alpha = 0.0

        logoImageView?.isHidden = false
        logoImageView?.alpha = 0.0
        
        appNameLabel?.isHidden = false
        appNameLabel?.alpha = 0.0
      
        addWalletItemButton?.isHidden = false
        addWalletItemButton?.alpha = 0.0
    }
    
    private func finalView() {
        stackView?.alpha = 1.0
        
        logoImageView?.alpha = 1.0
        appNameLabel?.alpha = 1.0
        addWalletItemButton?.alpha = 1.0
    }
    
    private func animateView() {
        defaultView()
        
        UIView.animate(withDuration: 2.0, animations: {
            self.finalView()
        })
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
