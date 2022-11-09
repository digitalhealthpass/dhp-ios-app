//
//  CustomNavigationController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class CustomNavigationController: UINavigationController {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setnavigationBarAttributes()
        setBarButtonItemsAttributes()

        isModalInPresentation = true
    }
    
    /// Navigation bar title and view method which applies default app font for title
    func setnavigationBarAttributes() {
        var backgroundColor = UIColor.systemBackground
        
        var titleTextAttributes = [NSAttributedString.Key.font: UIFont.navitaionBarTitleFont,
                                   NSAttributedString.Key.foregroundColor: UIColor.label]
        var largeTitleTextAttributes = [NSAttributedString.Key.font: UIFont.navitaionBarlargeTitleFont,
                                        NSAttributedString.Key.foregroundColor: UIColor.label]
        
        var tintColor = UIColor.label
        var shadowImage: UIImage? = UIImage()
        
        backgroundColor = UIColor.secondarySystemBackground
       
        titleTextAttributes = [NSAttributedString.Key.font: UIFont.navitaionBarTitleFont,
                               NSAttributedString.Key.foregroundColor: UIColor.label]
        largeTitleTextAttributes = [NSAttributedString.Key.font: UIFont.navitaionBarlargeTitleFont,
                                    NSAttributedString.Key.foregroundColor: UIColor.label]

        tintColor = UIColor.systemBlue
        shadowImage = UIImage.shadowImageWithColor(color: UIColor.clear)
                
        navigationBar.titleTextAttributes = titleTextAttributes
        navigationBar.largeTitleTextAttributes = largeTitleTextAttributes
        navigationBar.shadowImage = shadowImage

        navigationBar.tintColor = tintColor
        
        let standardAppearance = self.navigationBar.standardAppearance.copy()
        standardAppearance.backgroundColor = backgroundColor
        standardAppearance.titleTextAttributes = titleTextAttributes
        standardAppearance.largeTitleTextAttributes = largeTitleTextAttributes
        standardAppearance.shadowImage = shadowImage
        navigationBar.standardAppearance = standardAppearance
        
        let compactAppearance = self.navigationBar.compactAppearance?.copy() ?? UINavigationBarAppearance()
        compactAppearance.backgroundColor = backgroundColor
        compactAppearance.titleTextAttributes = titleTextAttributes
        compactAppearance.largeTitleTextAttributes = largeTitleTextAttributes
        compactAppearance.shadowImage = shadowImage
        navigationBar.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = self.navigationBar.scrollEdgeAppearance?.copy() ?? UINavigationBarAppearance()
        scrollEdgeAppearance.backgroundColor = backgroundColor
        scrollEdgeAppearance.titleTextAttributes = titleTextAttributes
        scrollEdgeAppearance.largeTitleTextAttributes = largeTitleTextAttributes
        scrollEdgeAppearance.shadowImage = shadowImage
        navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
        
        navigationBar.layoutIfNeeded()
    }
    
    /// Navigation bar button item method which applies default app font for button
    func setBarButtonItemsAttributes() {
        UIBarButtonItem.appearance().setTitleTextAttributes(
            [NSAttributedString.Key.font: UIFont.barButtonItemFont],
            for: UIControl.State.normal
        )
        
        UIBarButtonItem.appearance().setTitleTextAttributes(
            [NSAttributedString.Key.font: UIFont.barButtonItemFont],
            for: UIControl.State.highlighted
        )
        
        UIBarButtonItem.appearance().setTitleTextAttributes(
            [NSAttributedString.Key.font: UIFont.barButtonItemFont],
            for: UIControl.State.disabled
        )
    }
}

extension UIImage {
    static func shadowImageWithColor(color: UIColor, size: CGFloat = 13.0) -> UIImage? {
        let pixelScale = UIScreen.main.scale
        let pixelSize = size / pixelScale
        let fillSize = CGSize(width: pixelSize, height: pixelSize)
        let fillRect = CGRect(origin: CGPoint.zero, size: fillSize)
        UIGraphicsBeginImageContextWithOptions(fillRect.size, false, pixelScale)

        guard let graphicsContext = UIGraphicsGetCurrentContext() else { return nil }
        graphicsContext.setFillColor(color.cgColor)
        graphicsContext.fill(fillRect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    static func from(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
