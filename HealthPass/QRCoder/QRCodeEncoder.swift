//
//  QRCodeEncoder.swift
//  QRCoder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

/**
 
 A collection of helper functions for generating a QR code images.
 
 */
public class QRCodeEncoder {
    
    // ======================================================================
    // === Public  ==========================================================
    // ======================================================================
    
    /**
     The level of error correction. This controls the amount of additional data encoded in the output image to provide error correction. Higher levels result in larger output images but allow larger areas of the code to be damaged.
     
     - Low:                  7%
     - Medium:          15%
     - Quartile:           25%
     - High:                30%
     */
    
    public enum ErrorCorrection: String {
        case low = "L"
        case medium = "M"
        case quartile = "Q"
        case high = "H"
    }
    
    // MARK: - Public Methods
    
    public init() { }
    
    /**
     
     Gemerates a QR code image for a given dictionary along with additional optional properites.
     
     - parameter dictionary: Dictionary for which QRCode is generated
     - parameter size: Size of the output image. Defaults to `nil`, implies no scaling
     - parameter color: Foreground color of the output. Defaults to `.black`
     - parameter backgroundColor: Background color of the output. Defaults to `.white`
     - parameter errorCorrection: The error correction. The default value is `.low`.
     - parameter compressData: The compress flag which tells if the input data should be compressed. The default value is `nil`.
     - parameter completion: A closure of type (UIImage, Error) to be executed once the request has finished. This will provide the QR code for the dictionary
     
     */
    public func encode(for dictionary: [String: Any],
                       size: CGSize? = nil,
                       color: UIColor = .black,
                       backgroundColor: UIColor = .white,
                       errorCorrection: ErrorCorrection = .low,
                       compressData: Bool? = nil,
                       completion: ((UIImage?, Error?) -> Void)) {
        
        // Get string from the dictionary
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: JSONSerialization.WritingOptions()) as Data else {
            completion(nil, dataEncodingError)
            return
        }
        
        guard let string = String(data: jsonData, encoding: String.Encoding.utf8) else {
            completion(nil, dataEncodingError)
            return
        }
        
        QRCodeEncoder().encode(for: string, size: size, color: color, backgroundColor: backgroundColor, errorCorrection: errorCorrection, compressData: compressData, completion: completion)
        
    }
    
    /**
     
     Gemerates a QR code image for a given string along with additional optional properites.
     
     - parameter string: String for which QRCode is generated
     - parameter size: Size of the output image. Defaults to `nil`, implies no scaling
     - parameter color: Foreground color of the output. Defaults to `.black`
     - parameter backgroundColor: Background color of the output. Defaults to `.white`
     - parameter errorCorrection: The error correction. The default value is `.low`.
     - parameter compressData: The compress flag which tells if the input data should be compressed. The default value is `nil`.
     - parameter completion: A closure of type (UIImage, Error) to be executed once the request has finished. This will provide the QR code for the string
     
     */
    public func encode(for string: String,
                       size: CGSize? = nil,
                       color: UIColor = .black,
                       backgroundColor: UIColor = .white,
                       errorCorrection: ErrorCorrection = .low,
                       compressData: Bool? = nil,
                       completion: ((UIImage?, Error?) -> Void)) {
        
        // Get data from the string
        guard let data = string.data(using: String.Encoding.utf8) else {
            completion(nil, dataEncodingError)
            return
        }
        
        QRCodeEncoder().encode(for: data, size: size, color: color, backgroundColor: backgroundColor, errorCorrection: errorCorrection, compressData: compressData, completion: completion)
        
    }
    
    /**
     
     Gemerates a QR code image for a given data along with additional optional properites.
     
     - parameter data: Data for which QRCode is generated
     - parameter size: Size of the output image. Defaults to `nil`, implies no scaling
     - parameter color: Foreground color of the output. Defaults to `.black`
     - parameter backgroundColor: Background color of the output. Defaults to `.white`
     - parameter errorCorrection: The error correction. The default value is `.low`.
     - parameter compressData: The compress flag which tells if the input data should be compressed. The default value is `nil`.
     - parameter completion: A closure of type (UIImage, Error) to be executed once the request has finished. This will provide the QR code for the data
     
     */
    public func encode(for data: Data,
                       size: CGSize? = nil,
                       color: UIColor = .black,
                       backgroundColor: UIColor = .white,
                       errorCorrection: ErrorCorrection = .low,
                       compressData: Bool? = nil,
                       completion: ((UIImage?, Error?) -> Void)) {
        
        var dataToEncode = data
        
        var shouldCompressData: Bool = false
        if let compressData = compressData {
            shouldCompressData = compressData
        } else {
            shouldCompressData = (dataToEncode.count > Int(2953))
        }
        
        if shouldCompressData {
            guard let compressedData = try? (data as NSData).compressed(using: .zlib) as Data else {
                completion(nil, filterMissingError)
                return
            }
            
            dataToEncode = compressedData.base64EncodedData()
        }
        
        // Get a QR CIFilter
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else {
            completion(nil, filterMissingError)
            return
        }
        //qrFilter.setDefaults()
        
        // Input the data
        qrFilter.setValue(dataToEncode, forKey: "inputMessage")
        // Add error correction level
        qrFilter.setValue(errorCorrection.rawValue, forKey: "inputCorrectionLevel")
        
        // Get the output image
        guard let qrImage = qrFilter.outputImage else {
            if (dataToEncode.count > max_qrcode_data_size) {
                completion(nil, dataSizeError)
            } else {
                completion(nil, imageGenrationError)
            }
            return
        }
        
        // Color code and background
        guard let colorFilter = CIFilter(name: "CIFalseColor") else {
            completion(nil, filterMissingError)
            return
        }
        //colorFilter.setDefaults()
        
        // Input the data
        colorFilter.setValue(qrImage, forKey: "inputImage")
        // Add color
        colorFilter.setValue(CIColor(color: color), forKey: "inputColor0")
        // Add background color
        colorFilter.setValue(CIColor(color: backgroundColor), forKey: "inputColor1")
        
        // Get the output image
        guard let colorFilterImage = colorFilter.outputImage else {
            completion(nil, imageGenrationError)
            return
        }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledQrImage = colorFilterImage.transformed(by: transform)
        
        if let size = size {
            // Size
            let ciImageSize = colorFilterImage.extent.size
            let widthRatio = size.width / ciImageSize.width
            let heightRatio = size.height / ciImageSize.height
            
            let qrCodeImage = colorFilterImage.nonInterpolatedImage(withScale: Scale(dx: widthRatio, dy: heightRatio))
            completion(qrCodeImage, nil)
        } else {
            // Do some processing to get the UIImage
            let context = CIContext()
            guard let cgImage = context.createCGImage(scaledQrImage, from: scaledQrImage.extent) else {
                completion(nil, imageGenrationError)
                return
            }
            
            let qrCodeImage = UIImage(cgImage: cgImage)
            completion(qrCodeImage, nil)
        }
        
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private let dataEncodingError = NSError(domain: String("The receiver can’t be converted to a data representation"), code: Int(422), userInfo: nil)
    private let dataSizeError = NSError(domain: String("The input data is over the maximum amount of data that can be stored in the QR code"), code: Int(413), userInfo: nil)
    private let filterMissingError = NSError(domain: String("The specific kind of filter is not available in this device"), code: Int(404), userInfo: nil)
    private let imageGenrationError = NSError(domain: String("Couldn't generate QR code image for the reveiver"), code: Int(415), userInfo: nil)
    
    private let max_qrcode_data_size = Int(2953)
}

internal typealias Scale = (dx: CGFloat, dy: CGFloat)

internal extension CIImage {
    
    // ======================================================================
    // === Internal  ========================================================
    // ======================================================================
    
    // MARK:  Internal Methods
    
    /// Creates an `UIImage` with interpolation disabled and scaled given a scale property
    ///
    /// - parameter withScale:  a given scale using to resize the result image
    ///
    /// - returns: an non-interpolated UIImage
    func nonInterpolatedImage(withScale scale: Scale = Scale(dx: 1, dy: 1)) -> UIImage? {
        guard let cgImage = CIContext(options: nil).createCGImage(self, from: self.extent) else { return nil }
        let size = CGSize(width: self.extent.size.width * scale.dx, height: self.extent.size.height * scale.dy)
        
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.interpolationQuality = .none
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.draw(cgImage, in: context.boundingBoxOfClipPath)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }
}
