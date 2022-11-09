//
//  UIFont+Extension.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

extension UIFont {
    /// Navigation bar title font
    open class var navitaionBarTitleFont: UIFont {
        let font =  UIFont(name: AppFont.bold, size: 19.0) ?? UIFont.systemFont(ofSize: 19.0, weight: .bold)
        let fontMetrics = UIFontMetrics(forTextStyle: .title3)
        return fontMetrics.scaledFont(for: font)
    }
    
    /// Navigation bar large title font
    open class var navitaionBarlargeTitleFont: UIFont {
        let font = UIFont(name: AppFont.bold, size: 34.0) ?? UIFont.systemFont(ofSize: 34.0, weight: .bold)
        let fontMetrics = UIFontMetrics(forTextStyle: .largeTitle)
        return fontMetrics.scaledFont(for: font)
    }
    
    /// Navigation bar button item font
    open class var barButtonItemFont: UIFont {
        let font = UIFont(name: AppFont.semiBold, size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .semibold)
        let fontMetrics = UIFontMetrics(forTextStyle: .headline)
        return fontMetrics.scaledFont(for: font)
    }
    
    /// Alert title font
    open class var alertTitleFont: UIFont {
        let font = UIFont(name: AppFont.semiBold, size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .semibold)
        let fontMetrics = UIFontMetrics(forTextStyle: .headline)
        return fontMetrics.scaledFont(for: font)
    }
    
    /// Alert message font
    open class var alertMessageFont: UIFont {
        let font = UIFont(name: AppFont.regular, size: 14) ?? UIFont.systemFont(ofSize: 14)
        let fontMetrics = UIFontMetrics(forTextStyle: .callout)
        return fontMetrics.scaledFont(for: font)
    }
    
    open class var textFieldDefaultFont: UIFont {
        let font = UIFont(name: AppFont.regular, size: 17) ?? UIFont.systemFont(ofSize: 17)
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        return fontMetrics.scaledFont(for: font)
    }
}

extension UIResponder {
    var deviceIdiom: UIUserInterfaceIdiom {
        return UIScreen.main.traitCollection.userInterfaceIdiom
    }
    
    var isPhone: Bool {
        return (deviceIdiom == .phone)
    }
}
