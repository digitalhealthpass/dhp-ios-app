//
//  QRCodeDecoder.swift
//  QRCoder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

/**
 
 A collection of helper functions for extracting details from a QR code image.
 
 */
public class QRCodeDecoder {
    
    // ======================================================================
    // === Public  ==========================================================
    // ======================================================================
    
    /**
     The key in the options dictionary used to specify a accuracy / performance tradeoff to be used.
     
     There is a performance / accuracy tradeoff to be made. The default value will work well for most
     situations, but using these the detector will favour performance over accuracy or
     accuracy over performance.
     
     */
    
    public enum DetectorAccuracy {
        case low
        case high
    }
    
    // MARK: - Public Methods
    
    public init() { }
    
    /**
     
     Gemerates decoded messages for a given image(QR Code) along with additional optional properites.
     
     - parameter image: UIImage for which decoded message is generated
     - parameter detectorAccuracy: The detection accuracy for decoding. The default value is `.high`.
     - parameter completion: A closure of type ([String]?, [[String: Any?]]?, Error) to be executed once the request has finished. This will provide the decoded message for the given image
     
     */
    public func decode(image: UIImage,
                       detectorAccuracy: DetectorAccuracy = .high,
                       completion: ((_ message: [String]?, _ details: [[String: Any?]]?, _ error: Error?) -> Void)) {
        
        //Create Image detector
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil,
                                        options: [CIDetectorAccuracy: (detectorAccuracy == .high) ? CIDetectorAccuracyHigh : CIDetectorAccuracyLow ]) else {
                                            completion(nil, nil, detectorMissingError)
                                            return
        }
        
        //Convert UIImage to CGImage and CIImage
        guard let cgImage = image.cgImage else {
            completion(nil, nil, imageEncodingError)
            return
        }
        let ciImage = CIImage(cgImage: cgImage)
        
        //Generate all available features from the Image
        let features = detector.features(in: ciImage)
        
        //Extract only QR code features
        let qrCodeFeatures = features.compactMap { $0 as? CIQRCodeFeature }
        
        /*
         - mesage: Returns the receiver's QR Code decoded into a human-readable string.
         - isBase64Encoded: Indicates if the data is base64 encoded
         - rawMessage: The raw string that comprise the QR code symbol.
         - errorCorrection: The error correction level of the QR code.
         - errorCorrectedPayload: The error-corrected codewords that comprise the QR code symbol.
         - symbolVersion: The version property corresponds to the size of the QR Code.
         */
        
        let qrCoderDetails: [[String: Any?]] = qrCodeFeatures.compactMap { [
            "message": getDecodedMessage(message: $0.messageString),
            "rawMessage": $0.messageString,
            "isBase64Encoded": isBase64Encoded(message: $0.messageString),
            "errorCorrection": $0.symbolDescriptor?.errorCorrectionLevel,
            "errorCorrectedPayload": $0.symbolDescriptor?.errorCorrectedPayload,
            "symbolVersion": $0.symbolDescriptor?.symbolVersion,
            "maskPattern" : $0.symbolDescriptor?.maskPattern
            ] }
        
        //Extract only QR code messages
        let qrCodeMessages = qrCoderDetails.compactMap { $0["message"] as? String ?? $0["rawMessage"] as? String }
        
        //Check if the QR codes were decoded successfully
        guard qrCoderDetails.count > 0 else {
            completion(nil, nil, decodeFailedError)
            return
        }
        
        completion(qrCodeMessages, qrCoderDetails, nil)
        
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private let imageEncodingError = NSError(domain: String("The provided image can’t be converted to a data representation"), code: Int(422), userInfo: nil)
    private let detectorMissingError = NSError(domain: String("The specific kind of detector is not available in this device"), code: Int(404), userInfo: nil)
    private let decodeFailedError = NSError(domain: String("The provided image couldn't be decoded to data"), code: Int(404), userInfo: nil)
    
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
}
