//
//  GradientView.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit

class GradientView: ShadowView {
    
    @IBInspectable var primaryColor: UIColor = UIColor.white {
        didSet {
            updateView()
        }
    }
    
    //    @IBInspectable var secondaryColor: UIColor = UIColor.black {
    //        didSet {
    //            updateView()
    //        }
    //    }
    
    //    var gradientLayer = CAGradientLayer()
    
    override open class var layerClass: AnyClass {
        return CAGradientLayer.classForCoder()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        defaultView()
        
        //        gradientLayer = layer as? CAGradientLayer ?? CAGradientLayer()
        //
        //        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        //        gradientLayer.endPoint = CGPoint(x: 2.0, y: 1.0)
        //
        //        gradientLayer.colors = [primaryColor.cgColor, secondaryColor.cgColor]
    }
    
    private func defaultView() {
        layer.shadowColor = UIColor.clear.cgColor
        layer.borderColor = UIColor.secondaryLabel.cgColor
        layer.borderWidth = 0.5
        
        layer.shadowOpacity = shadowOpacity
        layer.shadowOffset = shadowOffset
        layer.shadowRadius = shadowRadius
        layer.cornerRadius = 8.0
        
        transform = CGAffineTransform.identity
    }
    
    func selectedView() {
        layer.borderColor = UIColor.systemBlue.cgColor
        layer.borderWidth = 4.0
        
        UIView.animate(withDuration: 0.15, animations: {
            self.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        }) { (finished) in
            UIView.animate(withDuration: 0.15, animations: {
                self.transform = CGAffineTransform.identity
            })
        }
    }
    
    func resetView() {
        layer.borderColor = UIColor.secondaryLabel.cgColor
        layer.borderWidth = 0.5
        
        transform = CGAffineTransform.identity
    }
    
    //Apply params
    override func updateView() {
        self.backgroundColor = primaryColor
        //        gradientLayer.colors = [primaryColor.cgColor, secondaryColor.cgColor]
    }
}
