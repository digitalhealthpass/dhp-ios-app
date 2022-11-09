//
//  ScanViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import AVFoundation
import MobileCoreServices
import QRCoder

class ScanViewController: UIViewController {
    
    @IBOutlet weak var scannerView: QRCodeScannerView!
    @IBOutlet weak var instructionLabel: UILabel!

    @IBOutlet var viewPlaceholder: UIView!
    @IBOutlet var settingsButton: PlatterButton!
   
    @IBOutlet weak var placeholder1Label: UILabel!
    @IBOutlet weak var placeholder2Label: UILabel!
    
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var optionsButton: UIButton!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        instructionLabel.font = AppFont.title3Scaled
        placeholder1Label.font = AppFont.bodyScaled
        placeholder2Label.font = AppFont.bodyScaled
        settingsButton.titleLabel?.font = AppFont.calloutScaled
        
        settingsButton.isProminent = true
        
        setupScanner()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        scannerView.startScanner()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        scannerView.stopScanner()
    }
    
    @IBAction func onSettings(_ sender: Any) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        generateImpactFeedback()
        UIApplication.shared.open(settingsUrl, completionHandler: nil)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? CustomNavigationController,
           let scanCompleteViewController = navigationController.viewControllers.first as? ScanCompleteViewController {
            scanCompleteViewController.credentialString = sender as? String ?? String()
        }
    }
    
    @IBAction func unwindToScan(segue: UIStoryboardSegue) {
        scannerView.startScanner()
    }
    
    @IBAction func onCancel(_ sender: Any) {
        performSegue(withIdentifier: unwindToWalletSegue, sender: nil)
    }
    
    @IBAction func onFlashlight(_ sender: Any) {
        generateImpactFeedback(style: .medium)
        scannerView.toggleFlash()
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private let scanCompleteSegue = "showScanComplete"
    private let unwindToWalletSegue = "unwindToWallet"
    
    // MARK: - Private Methods
    
    private func setupScanner() {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { isAuthorized in
            DispatchQueue.main.async {
                self.scannerView.initializeScanner()
                
                self.scannerView.delegate = self
                self.scannerView.stopScannerAfterDecode = false
                self.scannerView.showScanFrame = true
                
                self.instructionLabel.isHidden = !isAuthorized
                self.viewPlaceholder.isHidden = isAuthorized
                self.flashButton.isHidden = !isAuthorized
                
                self.flashButton.isHidden = !(self.scannerView.hasTorch)
            }
        })
    }
}

extension ScanViewController {
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Methods
    
    private func showScanComplete(with image: UIImage?) {
        guard let image = image else {
            //TODO: handle error here
            return
        }
        
        QRCodeDecoder().decode(image: image,
                               completion: { messages, details, error in
                                let detailsMessages = details?.compactMap { $0["message"] as? String ?? $0["rawMessage"] as? String }
                                if let error = error {
                                    let title = "wallet.decodeError.title".localized
                                    let message = error.localizedDescription
                                    self.showErrorAlert(title: title, message: message)
                                    return
                                } else if let messages = messages, let message = messages.first ?? detailsMessages?.first  {
                                    self.showScanComplete(with: message)
                                }
                                
                               })
        
    }
    
    private func showScanComplete(with message: String) {
        generateNotificationFeedback(.success)
        
        performSegue(withIdentifier: scanCompleteSegue, sender: message)
    }
    
    private func showErrorAlert(title: String, message: String) {
        generateNotificationFeedback(.error)
        
        scannerView.stopScanner()
        showConfirmation(title: title, message: message,
                         actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)]) { _ in
            self.scannerView.startScanner()
        }
    }
}

extension ScanViewController: QRCodeScannerViewDelegate {
    
    func scannerView(_ scannerView: QRCodeScannerView, didScanQRCodeMessages messages: [String]) { }
    
    func scannerView(_ scannerView: QRCodeScannerView, didReceiveError error: Error) { }
    
    func scannerView(_ scannerView: QRCodeScannerView, didScanQRCodeDetails details: [[String : Any]]) {
        scannerView.stopScanner()
        
        let messages = (details.compactMap { $0["message"] as? String ?? $0["rawMessage"] as? String }).filter { !($0.isEmpty) }
        print(String(format: "[RESPONSE] - Credential Scan: %@", messages))
        
        guard let message = messages.first else {
            showErrorAlert(title: "scan.invalid.title".localized, message: "scan.invalid.message.wallet".localized)
            return
        }
        
        showScanComplete(with: message)
    }
    
    
}
