//
//  QRCodeScannerView.swift
//  QRCoder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import AVFoundation

public typealias ScannerInitializationCompletion = (Bool) -> Void

@objc public protocol QRCodeScannerViewDelegate: AnyObject {
    /**
     Called whenever QR code was scanned and was successfully be able to decoded
     
     - parameter scannerView: Current QR Coder Scanner view.
     - parameter messages: Returns the receiver's QR Code decoded into a human-readable string.
     */
    func scannerView(_ scannerView: QRCodeScannerView, didScanQRCodeMessages messages: [String])
    
    /**
     Called whenever QR codes were scanned successfully at frame
     
     - parameter scannerView: Current QR Coder Scanner view.
     - parameter details: Returns the receiver's QR Code decoded into a detailed object.
     
     @discussion
     - mesage: Returns the receiver's QR Code decoded into a human-readable string.
     - isBase64Encoded: Indicates if the data is base64 encoded
     - rawMessage: The raw string that comprise the QR code symbol.
     - errorCorrection: The error correction level of the QR code.
     - errorCorrectedPayload: The error-corrected codewords that comprise the QR code symbol.
     - symbolVersion: The version property corresponds to the size of the QR Code.
     - frame: The bounding rectangle of the QR code.
     
     */
    @objc optional func scannerView(_ scannerView: QRCodeScannerView, didScanQRCodeDetails details: [[String: Any]])
    
    /**
     Called when a device setup or a decode fails
     
     - parameter scannerView: Current QR Coder Scanner view.
     
     */
    @objc optional func scannerView(_ scannerView: QRCodeScannerView, didReceiveError error: Error)
}

/**
 
 A custom UIView which can bring a device camera and start scanning for QR code images. The scanned QR code image also provides details about it.
 
 */

public class QRCodeScannerView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func initializeScanner(completion: ScannerInitializationCompletion? = nil) {
        setupScanner(completion: completion)
    }
    
    deinit {
        stopScanner()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        videoPreviewLayer?.frame = layer.bounds
    }
    
    // ======================================================================
    // === Public  ==========================================================
    // ======================================================================
    
    // MARK: - Public Properties
    
    /**
     Defines an interface for delegates of QRCodeScannerViewDelegate to receive emitted objects.
     */
    public weak var delegate : QRCodeScannerViewDelegate?
    
    /**
     Indicates whether the scanner should stop after scanning a QR code.
     */
    public var stopScannerAfterDecode: Bool = true
    
    /**
     Indicates whether the scanner should show the scanned frame.
     */
    public var showScanFrame: Bool = true
    
    /**
     Indicates whether the device has torch feature.
     */
    public var hasTorch: Bool {
        get {
            return currentCaptureDevice?.hasTorch ?? false
        }
    }
    
    /**
     Indicates whether the device has front camera.
     */
    public var hasFrontCamera: Bool {
        get {
            return (frontCaptureDevice != nil)
        }
    }
    
    // MARK: - Public Methods
    
    /**
     Returns the camera authorization status for scanning QR code
     */
    
    public func getCameraStatus() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    /**
     Starts the Scanner instance running.
     */
    
    public func startScanner() {
        if !captureSession.isRunning {
            removeQRCoderFrame(view: qrCodeFrameView1, layer: qrCodeShapelayer1)
            removeQRCoderFrame(view: qrCodeFrameView2, layer: qrCodeShapelayer2)
            removeQRCoderFrame(view: qrCodeFrameView3, layer: qrCodeShapelayer3)
            
            captureSession.startRunning()
        }
    }
    
    /**
     Tells the Scanner to stop running.
     */
    public func stopScanner() {
        if captureSession.isRunning {
            removeQRCoderFrame(view: qrCodeFrameView1, layer: qrCodeShapelayer1)
            removeQRCoderFrame(view: qrCodeFrameView2, layer: qrCodeShapelayer2)
            removeQRCoderFrame(view: qrCodeFrameView3, layer: qrCodeShapelayer3)
            
            captureSession.stopRunning()
        }
    }
    
    /**
     Toggles the illumination of the torch mode.
     
     - parameter enable: Boolean which indicates if the flash light to be toggled on/off
     
     */
    
    public func toggleFlash(enable: Bool? = nil) {
        guard hasTorch else { return }
        
        do {
            try currentCaptureDevice?.lockForConfiguration()
            
            if (currentCaptureDevice?.torchMode == AVCaptureDevice.TorchMode.on) || enable == false {
                currentCaptureDevice?.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                do {
                    try currentCaptureDevice?.setTorchModeOn(level: 1.0)
                } catch {
                    delegate?.scannerView?(self, didReceiveError: cameraDeviceError)
                }
            }
            
            currentCaptureDevice?.unlockForConfiguration()
        } catch {
            delegate?.scannerView?(self, didReceiveError: cameraDeviceError)
        }
    }
    
    /**
     Toggles the Position of the camera.
     
     - parameter position: AVCaptureDevice.Position which indicates the toggle position of the camera
     
     */
    public func toggleCameraPosition() {
        captureSession.inputs.forEach { input in
            captureSession.removeInput(input)
        }
        
        if currentCaptureDevice?.position == .back {
            currentCaptureDevice = frontCaptureDevice
        } else {
            currentCaptureDevice = backCaptureDevice
        }
        
        if let currentCamera = currentCaptureDevice, let captureDeviceInput = try? AVCaptureDeviceInput(device: currentCamera) {
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }
        }
    }
    
    public func frontCameraPosition() {
        guard let position = currentCaptureDevice?.position, position == .back else { return }
        
        captureSession.inputs.forEach { input in
            captureSession.removeInput(input)
        }
        
        currentCaptureDevice = frontCaptureDevice
        
        if let currentCamera = currentCaptureDevice, let captureDeviceInput = try? AVCaptureDeviceInput(device: currentCamera) {
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }
        }
    }
    
    public func backCameraPosition() {
        guard let position = currentCaptureDevice?.position, position == .front else { return }
        
        captureSession.inputs.forEach { input in
            captureSession.removeInput(input)
        }
        
        currentCaptureDevice = backCaptureDevice
        
        if let currentCamera = currentCaptureDevice, let captureDeviceInput = try? AVCaptureDeviceInput(device: currentCamera) {
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private var captureSession = AVCaptureSession()
    
    private var currentCaptureDevice: AVCaptureDevice?
    
    private var frontCaptureDevice: AVCaptureDevice?
    private var backCaptureDevice: AVCaptureDevice?
    
    private var frontCaptureInput: AVCaptureInput?
    private var backCaptureInput: AVCaptureInput?
    
    private var discoverySession: AVCaptureDevice.DiscoverySession?
    
    private var videoPreviewLayer: QRCodeCaptureVideoPreviewLayer?
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.qr]
    
    private let qrCodeShapelayer1 = CAShapeLayer()
    private var qrCodeFrameView1 = UIView()
    
    private let qrCodeShapelayer2 = CAShapeLayer()
    private var qrCodeFrameView2 = UIView()
    
    private let qrCodeShapelayer3 = CAShapeLayer()
    private var qrCodeFrameView3 = UIView()
    
    private let cameraDeviceError = NSError(domain: String("Failed to get the camera device"), code: Int(404), userInfo: nil)
    
    // MARK: - Private Methods
    
    private func setupScanner(completion: ScannerInitializationCompletion?) {
        frontCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        backCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)

        currentCaptureDevice = backCaptureDevice ?? frontCaptureDevice

        if let currentCamera = currentCaptureDevice, let captureDeviceInput = try? AVCaptureDeviceInput(device: currentCamera) {
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }
        }

        // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
        let captureMetadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(captureMetadataOutput) {
            captureSession.addOutput(captureMetadataOutput)
        }

        // Set delegate and use the default dispatch queue to execute the call back
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = QRCodeCaptureVideoPreviewLayer(session: captureSession)

        guard let videoPreviewLayer = videoPreviewLayer else {
            return
        }

        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = layer.bounds
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            videoPreviewLayer.maskSize = CGSize(width: layer.bounds.width/1.5, height: layer.bounds.width/1.5)
        } else {
            videoPreviewLayer.maskSize = CGSize(width: layer.bounds.height/2, height: layer.bounds.height/2)
        }
        
        
        if let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation,
           let connection = videoPreviewLayer.connection, connection.isVideoOrientationSupported {
            switch interfaceOrientation {
            case .portrait:
                connection.videoOrientation = AVCaptureVideoOrientation.portrait
            case .portraitUpsideDown:
                connection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            case .landscapeLeft:
                connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            case .landscapeRight:
                connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            default: break
            }
        }

        layer.addSublayer(videoPreviewLayer)

        AVCaptureDevice.requestAccess(for: .video, completionHandler: { isAuthorized in
            if isAuthorized {
                if Set(captureMetadataOutput.availableMetadataObjectTypes).isSuperset(of: Set(self.supportedCodeTypes)) {
                    captureMetadataOutput.metadataObjectTypes = self.supportedCodeTypes
                }

                // Start video capture.
                self.captureSession.startRunning()
                
                // notify caller on main thread
                DispatchQueue.main.async {
                    completion?(isAuthorized)
                }
            }
        })

    }
    
    private func showResults(qrCodeMachineReadableObjects: [AVMetadataMachineReadableCodeObject?]) {
        var qrCodeMessages = [String]()
        var qrCodeDetails = [[String: Any]]()
        
        for (index, qrCodeMachineReadableObject) in qrCodeMachineReadableObjects.enumerated() {
            
            if let qrCodeMachineReadableObject = qrCodeMachineReadableObject {
                let qrCodeMessage = qrCodeMachineReadableObject.stringValue ?? String()
                let isBase64Encoded = self.isBase64Encoded(message: qrCodeMessage)
                let decodedMessage = getDecodedMessage(message: qrCodeMessage)
                qrCodeMessages.append(decodedMessage ?? qrCodeMessage)
                
                var qrCodeDetail = [String: Any]()
                qrCodeDetail["rawMessage"] = qrCodeMessage
                qrCodeDetail["isBase64Encoded"] = isBase64Encoded
                qrCodeDetail["message"] = decodedMessage
                
                let rawReadableObjectTemp = qrCodeMachineReadableObject.value(forKeyPath: "_internal.basicDescriptor")! as! [String:Any]
                let rawReadableObject = rawReadableObjectTemp["BarcodeRawData"] as? Data
                qrCodeDetail["rawData"] = rawReadableObject
                
                if showScanFrame, let qrCodeObject = videoPreviewLayer?.transformedMetadataObject(for: qrCodeMachineReadableObject) {
                    if let qrCodeDescriptor = qrCodeMachineReadableObject.descriptor as? CIQRCodeDescriptor {
                        
                        let errorCorrection = qrCodeDescriptor.errorCorrectionLevel.rawValue
                        switch errorCorrection {
                        case CIQRCodeDescriptor.ErrorCorrectionLevel.levelL.rawValue:
                            qrCodeDetail["errorCorrection"] = QRCodeEncoder.ErrorCorrection.low
                        case CIQRCodeDescriptor.ErrorCorrectionLevel.levelM.rawValue:
                            qrCodeDetail["errorCorrection"] = QRCodeEncoder.ErrorCorrection.medium
                        case CIQRCodeDescriptor.ErrorCorrectionLevel.levelH.rawValue:
                            qrCodeDetail["errorCorrection"] = QRCodeEncoder.ErrorCorrection.high
                        default:
                            qrCodeDetail["errorCorrection"] = QRCodeEncoder.ErrorCorrection.quartile
                        }
                        
                        let errorCorrectedPayload = qrCodeDescriptor.errorCorrectedPayload
                        qrCodeDetail["errorCorrectedPayload"] = errorCorrectedPayload
                        
                        let symbolVersion = qrCodeDescriptor.symbolVersion
                        qrCodeDetail["symbolVersion"] = symbolVersion
                        
                        let qrCodeBounds = qrCodeObject.bounds
                        qrCodeDetail["frame"] = qrCodeBounds
                        
                        if index == 0 {
                            addQRCoderFrame(view: qrCodeFrameView1, frame: qrCodeBounds, layer: qrCodeShapelayer1)
                        } else if index == 1 {
                            addQRCoderFrame(view: qrCodeFrameView2, frame: qrCodeBounds, layer: qrCodeShapelayer2)
                        } else if index == 2 {
                            addQRCoderFrame(view: qrCodeFrameView3, frame: qrCodeBounds, layer: qrCodeShapelayer3)
                        }
                        
                        qrCodeDetails.append(qrCodeDetail)
                    }
                }
            }
        }
        
        if qrCodeMessages.count > 0 && stopScannerAfterDecode {
            captureSession.stopRunning()
        }
        
        delegate?.scannerView(self, didScanQRCodeMessages: qrCodeMessages)
        delegate?.scannerView?(self, didScanQRCodeDetails: qrCodeDetails)
    }
    
    private func addQRCoderFrame(view: UIView, frame: CGRect, layer: CAShapeLayer) {
        view.frame = frame
        
        layer.strokeColor = UIColor.white.cgColor
        layer.lineWidth = 3
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.lineDashPattern = [10, 10]
        layer.frame = view.bounds
        layer.fillColor = nil
        layer.path = UIBezierPath(rect: view.bounds).cgPath
        
        view.layer.addSublayer(layer)
        
        addSubview(view)
        bringSubviewToFront(view)
    }
    
    private func removeQRCoderFrame(view: UIView, layer: CAShapeLayer) {
        view.frame = CGRect.zero
        
        layer.frame = view.bounds
        layer.path = UIBezierPath(rect: view.bounds).cgPath
        
        view.layer.addSublayer(layer)
        
        view.removeFromSuperview()
    }
    
    private func isBase64Encoded(message: String?) -> Bool {
        guard let message = message else {
            return false
        }
        
        return (Data(base64Encoded: message) != nil)
    }
    
    private func getDecodedMessage(message: String?) -> String? {
        guard let message = message else {
            return nil
        }
        
        guard isBase64Encoded(message: message) else {
            return message
        }
        
        guard let base64DecodedMessageData = Data(base64Encoded: message) else {
            return nil
        }
        
        guard let deompressedMessageData = try? (base64DecodedMessageData as NSData).decompressed(using: .zlib) as Data else {
            return nil
        }
        
        return String(bytes: deompressedMessageData, encoding: .utf8)
    }
    
    // ======================================================================
    // === AVCaptureMetadataOutputObjectsDelegate  ==========================
    // ======================================================================
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            removeQRCoderFrame(view: qrCodeFrameView1, layer: qrCodeShapelayer1)
            removeQRCoderFrame(view: qrCodeFrameView2, layer: qrCodeShapelayer2)
            removeQRCoderFrame(view: qrCodeFrameView3, layer: qrCodeShapelayer3)
            return
        }
        
        // Get the metadata object.
        let allMachineReadableCodeObjects = metadataObjects.map { $0 as? AVMetadataMachineReadableCodeObject }
        var allQRCodeMachineReadableObjects = allMachineReadableCodeObjects.compactMap { return ($0?.type == AVMetadataObject.ObjectType.qr) ? $0 : nil }
        
        if allQRCodeMachineReadableObjects.count > 3 { allQRCodeMachineReadableObjects = Array(allQRCodeMachineReadableObjects.prefix(3)) }
        
        switch allQRCodeMachineReadableObjects.count {
        case 2:
            removeQRCoderFrame(view: qrCodeFrameView3, layer: qrCodeShapelayer3)
        case 1:
            removeQRCoderFrame(view: qrCodeFrameView2, layer: qrCodeShapelayer2)
            removeQRCoderFrame(view: qrCodeFrameView3, layer: qrCodeShapelayer3)
        case 0:
            removeQRCoderFrame(view: qrCodeFrameView1, layer: qrCodeShapelayer1)
            removeQRCoderFrame(view: qrCodeFrameView2, layer: qrCodeShapelayer2)
            removeQRCoderFrame(view: qrCodeFrameView3, layer: qrCodeShapelayer3)
        default:
            break
        }
        
        showResults(qrCodeMachineReadableObjects: allQRCodeMachineReadableObjects)
    }
    
}
