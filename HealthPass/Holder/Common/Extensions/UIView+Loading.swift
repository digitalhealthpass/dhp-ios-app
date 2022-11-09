//
//  UIView+Loading.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

extension UIView {
    func showActivityIndicator(_ aiColor: UIActivityIndicatorView.Style = .medium) -> UIActivityIndicatorView? {
        let indicators = subviews.filter { $0 is UIActivityIndicatorView }
        
        if let activeIndicator = indicators.first as? UIActivityIndicatorView {
            activeIndicator.stopAnimating()
        }
        
        let activityIndicator = UIActivityIndicatorView(style: aiColor)
        activityIndicator.center = center
        activityIndicator.transform = CGAffineTransform(scaleX: 2, y: 2)
        if !activityIndicator.isAnimating {
            activityIndicator.startAnimating()
        }

        addSubview(activityIndicator)

        return activityIndicator
    }
    
}

