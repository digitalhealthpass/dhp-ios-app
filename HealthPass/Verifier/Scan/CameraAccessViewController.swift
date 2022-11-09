//
//  CameraAccessViewController.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import AVFoundation
import QRCoder

class CameraAccessViewController: UIViewController {
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        infoTitleLabel?.font = AppFont.title1Scaled
        infoMessageLabel?.font = AppFont.bodyScaled
        settingsButton?.titleLabel?.font = AppFont.headlineScaled
        
        settingsButton?.isProminent = true
        settingsButton?.titleLabel?.adjustsFontSizeToFitWidth = true
        isModalInPresentation = true
        
        updateView()
    }
    
    // MARK: - IBOutlet
    @IBOutlet var settingsButton: PlatterButton?
    @IBOutlet weak var infoTitleLabel: UILabel?
    @IBOutlet weak var infoMessageLabel: UILabel?
    
    // MARK: - IBAction
    @IBAction func onSettings(_ sender: Any) {
        guard let authorizationStatus = scannerView?.getCameraStatus() else { return }
        
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            UIApplication.shared.open(settingsUrl, completionHandler: nil)
        } else {
            scannerView?.initializeScanner(completion: { isAuthorized in
                if isAuthorized {
                    self.performSegue(withIdentifier: "unwindToScan", sender: nil)
                } else {
                    self.updateView()
                }
            })
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Methods
    
    var scannerView: QRCodeScannerView?
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Methods
    
    private func updateView() {
        guard let authorizationStatus = scannerView?.getCameraStatus() else { return }
        
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            infoMessageLabel?.text = "CameraAccess.cameraAccess.message1".localized
            settingsButton?.setTitle("CameraAccess.cameraAccess.button1".localized, for: .normal)
        } else if authorizationStatus == .notDetermined {
            infoMessageLabel?.text = "CameraAccess.cameraAccess.message2".localized
            settingsButton?.setTitle("CameraAccess.cameraAccess.button2".localized, for: .normal)
        }
    }
    
}
