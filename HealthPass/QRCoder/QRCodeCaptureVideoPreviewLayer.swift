//
//  ScannerOverlayPreviewLayer.swift
//  QRCoder
//
//  Created by Yevtushenko Valeriia on 16.02.2022.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import AVFoundation
import UIKit

class QRCodeCaptureVideoPreviewLayer: AVCaptureVideoPreviewLayer {

    // MARK: - OverlayScannerPreviewLayer
    private var cornerLength: CGFloat = 40
    private let lineWidth: CGFloat = 4
    private let lineColor: UIColor = .systemGreen
    private let lineCap: CAShapeLayerLineCap = .round
    private let cornerSize : CGFloat = 10
    var maskSize: CGSize = CGSize(width: 200, height: 200)
    
    override var frame: CGRect {
        didSet {
            setNeedsDisplay()
        }
    }

    private var maskContainer: CGRect {
        CGRect(x: (bounds.width / 2) - (maskSize.width / 2),
        y: (bounds.height / 2) - (maskSize.height / 2),
        width: maskSize.width, height: maskSize.height)
    }

    // MARK: - Drawing
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        
        sublayers?.filter{ $0 is CAShapeLayer }.forEach{ $0.removeFromSuperlayer() }
        let path = CGMutablePath()
        path.addRect(bounds)
        path.addRoundedRect(in: maskContainer, cornerWidth: cornerSize, cornerHeight: cornerSize)

        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        maskLayer.fillColor = UIColor.black.withAlphaComponent(0.3).cgColor
        maskLayer.fillRule = .evenOdd

        addSublayer(maskLayer)

        cornerLength = maskContainer.width / 6
      
        let upperLeftPoint = CGPoint(x: maskContainer.minX, y: maskContainer.minY)
        let upperRightPoint = CGPoint(x: maskContainer.maxX, y: maskContainer.minY)
        let lowerRightPoint = CGPoint(x: maskContainer.maxX, y: maskContainer.maxY)
        let lowerLeftPoint = CGPoint(x: maskContainer.minX, y: maskContainer.maxY)
    
        let upperLeftCorner = UIBezierPath()
        upperLeftCorner.move(to: upperLeftPoint.offsetBy(dx: 0, dy: cornerLength))
        upperLeftCorner.addArc(withCenter: upperLeftPoint.offsetBy(dx: cornerSize, dy: cornerSize),
                         radius: cornerSize, startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: true)
        upperLeftCorner.addLine(to: upperLeftPoint.offsetBy(dx: cornerLength, dy: 0))

        let upperRightCorner = UIBezierPath()
        upperRightCorner.move(to: upperRightPoint.offsetBy(dx: -cornerLength, dy: 0))
        upperRightCorner.addArc(withCenter: upperRightPoint.offsetBy(dx: -cornerSize, dy: cornerSize),
                              radius: cornerSize, startAngle: 3 * .pi / 2, endAngle: 0, clockwise: true)
        upperRightCorner.addLine(to: upperRightPoint.offsetBy(dx: 0, dy: cornerLength))

        let lowerRightCorner = UIBezierPath()
        lowerRightCorner.move(to: lowerRightPoint.offsetBy(dx: 0, dy: -cornerLength))
        lowerRightCorner.addArc(withCenter: lowerRightPoint.offsetBy(dx: -cornerSize, dy: -cornerSize),
                                 radius: cornerSize, startAngle: 0, endAngle: .pi / 2, clockwise: true)
        lowerRightCorner.addLine(to: lowerRightPoint.offsetBy(dx: -cornerLength, dy: 0))

        let bottomLeftCorner = UIBezierPath()
        bottomLeftCorner.move(to: lowerLeftPoint.offsetBy(dx: cornerLength, dy: 0))
        bottomLeftCorner.addArc(withCenter: lowerLeftPoint.offsetBy(dx: cornerSize, dy: -cornerSize),
                                radius: cornerSize, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        bottomLeftCorner.addLine(to: lowerLeftPoint.offsetBy(dx: 0, dy: -cornerLength))
        
        let combinedPath = CGMutablePath()
        combinedPath.addPath(upperLeftCorner.cgPath)
        combinedPath.addPath(upperRightCorner.cgPath)
        combinedPath.addPath(lowerRightCorner.cgPath)
        combinedPath.addPath(bottomLeftCorner.cgPath)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = combinedPath
        shapeLayer.strokeColor = lineColor.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineCap = lineCap
        
        addSublayer(shapeLayer)
        setLayerAnimation(shapeLayer)
    }
    
    private func setLayerAnimation(_ layer:  CALayer) {
        let animation = CABasicAnimation(keyPath: "strokeColor")
        animation.toValue = UIColor.systemGreen.withAlphaComponent(0.1).cgColor
        animation.fromValue = UIColor.systemGreen.cgColor
        animation.duration = 1.5
        animation.autoreverses = true
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.repeatCount = Float.infinity
        layer.add(animation, forKey: nil)
    }
}

extension CGPoint {
    func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        var point = self
        point.x += dx
        point.y += dy
        return point
    }
}
