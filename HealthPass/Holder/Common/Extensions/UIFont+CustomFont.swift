//
//  UIFont+CustomFont.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

public struct AppFont {
    static let regular = "IBMPlexSans"
    static let bold = "IBMPlexSans-Bold"
    static let italic = "IBMPlexSans-Italic"
    
    static let thin = "IBMPlexSans-Thin"
    static let thinItalic = "IBMPlexSans-ThinItalic"
    static let extraLight = "IBMPlexSans-ExtraLight"
    static let extraLightItalic = "IBMPlexSans-ExtraLightItalic"
    static let light = "IBMPlexSans-Light"
    static let lightItalic = "IBMPlexSans-LightItalic"
    static let medium = "IBMPlexSans-Medium"
    static let mediumItalic = "IBMPlexSans-MediumItalic"
    static let semiBold = "IBMPlexSans-SemiBold"
    static let semiBoldItalic = "IBMPlexSans-SemiBoldItalic"
    static let boldItalic = "IBMPlexSans-BoldItalic"
    
    //AppFont dynamic fonts
    private static let largeTitle = UIFont(name: AppFont.regular, size: 34) ?? UIFont.preferredFont(forTextStyle: .largeTitle)
    private static let title1 = UIFont(name: AppFont.regular, size: 28) ?? UIFont.preferredFont(forTextStyle: .title1)
    private static let title2 = UIFont(name: AppFont.regular, size: 22) ?? UIFont.preferredFont(forTextStyle: .title2)
    private static let title3 = UIFont(name: AppFont.regular, size: 20) ?? UIFont.preferredFont(forTextStyle: .title3)
    private static let headline = UIFont(name: AppFont.semiBold, size: 17) ?? UIFont.preferredFont(forTextStyle: .headline)
    private static let body = UIFont(name: AppFont.regular, size: 17) ?? UIFont.preferredFont(forTextStyle: .body)
    private static let callout = UIFont(name: AppFont.regular, size: 16) ?? UIFont.preferredFont(forTextStyle: .callout)
    private static let subheadline = UIFont(name: AppFont.regular, size: 15) ?? UIFont.preferredFont(forTextStyle: .subheadline)
    private static let footnote = UIFont(name: AppFont.regular, size: 13) ?? UIFont.preferredFont(forTextStyle: .footnote)
    private static let caption1 = UIFont(name: AppFont.regular, size: 12) ?? UIFont.preferredFont(forTextStyle: .caption1)
    private static let caption2 = UIFont(name: AppFont.regular, size: 11) ?? UIFont.preferredFont(forTextStyle: .caption2)
    
    //AppFont font metrics
    private static let largeTitleMetrics = UIFontMetrics(forTextStyle: .largeTitle)
    private static let title1Metrics = UIFontMetrics(forTextStyle: .title1)
    private static let title2Metrics = UIFontMetrics(forTextStyle: .title2)
    private static let title3Metrics = UIFontMetrics(forTextStyle: .title3)
    private static let headlineMetrics = UIFontMetrics(forTextStyle: .headline)
    private static let bodyMetrics = UIFontMetrics(forTextStyle: .body)
    private static let calloutMetrics = UIFontMetrics(forTextStyle: .callout)
    private static let subheadlineMetrics = UIFontMetrics(forTextStyle: .subheadline)
    private static let footnoteMetrics = UIFontMetrics(forTextStyle: .footnote)
    private static let caption1Metrics = UIFontMetrics(forTextStyle: .caption1)
    private static let caption2Metrics = UIFontMetrics(forTextStyle: .caption2)
    
    //AppFont scaled fonts
    static let largeTitleScaled = largeTitleMetrics.scaledFont(for: largeTitle)
    static let title1Scaled = title1Metrics.scaledFont(for: title1)
    static let title2Scaled = title2Metrics.scaledFont(for: title2)
    static let title3Scaled = title3Metrics.scaledFont(for: title3)
    static let headlineScaled = headlineMetrics.scaledFont(for: headline)
    static let bodyScaled = bodyMetrics.scaledFont(for: body)
    static let calloutScaled = calloutMetrics.scaledFont(for: callout)
    static let subheadlineScaled = subheadlineMetrics.scaledFont(for: subheadline)
    static let footnoteScaled = footnoteMetrics.scaledFont(for: footnote)
    static let caption1Scaled = caption1Metrics.scaledFont(for: caption1)
    static let caption2Scaled = caption2Metrics.scaledFont(for: caption1)
}

extension UIFontDescriptor.AttributeName {
    static let nsctFontUIUsage = UIFontDescriptor.AttributeName(rawValue: "NSCTFontUIUsageAttribute")
    
    static let nsFontSize = UIFontDescriptor.AttributeName(rawValue: "NSFontSizeAttribute")
    static let nsFontName = UIFontDescriptor.AttributeName(rawValue: "NSFontNameAttribute")
}

extension UIFont {
    
    @objc class func mySystemFont(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: AppFont.regular, size: size)!
    }
    
    @objc class func mySystemFont(ofSize fontSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        var fontName = AppFont.regular
        
        switch weight {
        case .ultraLight:
            fontName = AppFont.extraLight
            
        case .thin:
            fontName = AppFont.thin
            
        case .light:
            fontName = AppFont.light
            
        case .regular:
            fontName = AppFont.regular
            
        case .medium:
            fontName = AppFont.medium
            
        case .semibold:
            fontName = AppFont.semiBold
            
        case .bold:
            fontName = AppFont.bold
            
        case .heavy:
            fontName = AppFont.bold
            
        case .black:
            fontName = AppFont.bold
            
        default:
            fontName = AppFont.regular
        }
        
        return UIFont(name: fontName, size: fontSize)!
    }
    
    @objc class func myBoldSystemFont(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: AppFont.bold, size: size)!
    }
    
    @objc class func myItalicSystemFont(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: AppFont.italic, size: size)!
    }
    
    @objc class func myPreferredFont(forTextStyle style: UIFont.TextStyle) -> UIFont {
        let fontName = (style == .headline) ? AppFont.regular : AppFont.semiBold
        
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        desc.addingAttributes([UIFontDescriptor.AttributeName.name: fontName,
                               UIFontDescriptor.AttributeName.family: fontName,
                               UIFontDescriptor.AttributeName.size: desc.pointSize,
                               UIFontDescriptor.AttributeName.textStyle: style])

        return UIFont(descriptor: desc, size: desc.pointSize)
    }
    
    @objc class func myPreferredFont(forTextStyle style: UIFont.TextStyle, compatibleWith traitCollection: UITraitCollection?) -> UIFont {
        let fontName = (style == .headline) ? AppFont.regular : AppFont.semiBold
        
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style, compatibleWith: traitCollection)
        desc.addingAttributes([UIFontDescriptor.AttributeName.name: fontName,
                               UIFontDescriptor.AttributeName.family: fontName,
                               UIFontDescriptor.AttributeName.size: desc.pointSize,
                               UIFontDescriptor.AttributeName.textStyle: style])

        return UIFont(descriptor: desc, size: desc.pointSize)
    }
    
    @objc convenience init(myCoder aDecoder: NSCoder) {
        guard let fontDescriptor = aDecoder.decodeObject(forKey: "UIFontDescriptor") as? UIFontDescriptor else {
            self.init(myCoder: aDecoder)
            return
        }
        
        guard let fontAttribute = fontDescriptor.fontAttributes[.nsctFontUIUsage] as? String else {
            let fontName = fontDescriptor.fontAttributes[.nsFontName] as? String ?? AppFont.regular
            let pointSize = fontDescriptor.fontAttributes[.nsFontSize] as? CGFloat ?? 13.0
            self.init(name: fontName, size: pointSize)!
            return
        }
        
        var fontName = String()
        let pointSize = fontDescriptor.pointSize
        
        switch fontAttribute {
        case "CTFontRegularUsage":
            fontName = AppFont.regular
            
        case "CTFontThinUsage":
            fontName = AppFont.thin
            
        case "CTFontUltraLightUsage":
            fontName = AppFont.extraLight
            
        case "CTFontLightUsage":
            fontName = AppFont.light
            
        case "CTFontMediumUsage":
            fontName = AppFont.medium
            
        case "CTFontDemiUsage":
            fontName = AppFont.semiBold
            
        case "CTFontEmphasizedUsage", "CTFontBoldUsage", "CTFontBlackUsage", "CTFontHeavyUsage":
            fontName = AppFont.bold
            
        case "CTFontObliqueUsage":
            fontName = AppFont.italic
            
        default:
            fontName = AppFont.regular
        }
        
        self.init(name: fontName, size: pointSize)!
    }
    
    class func overrideInitialize() {
        guard self == UIFont.self else {
            return
        }
        
        if let systemFontMethod = class_getClassMethod(self, #selector(systemFont(ofSize:))),
           let mySystemFontMethod = class_getClassMethod(self, #selector(mySystemFont(ofSize:))) {
            method_exchangeImplementations(systemFontMethod, mySystemFontMethod)
        }
        
        if let systemFontMethod2 = class_getClassMethod(self, #selector(systemFont(ofSize:weight:))),
           let mySystemFontMethod2 = class_getClassMethod(self, #selector(mySystemFont(ofSize:weight:))) {
            method_exchangeImplementations(systemFontMethod2, mySystemFontMethod2)
        }
        
        if let monospacedDigitSystemFontMethod = class_getClassMethod(self, #selector(monospacedDigitSystemFont(ofSize:weight:))),
           let myMonospacedDigitSystemFontMethod = class_getClassMethod(self, #selector(mySystemFont(ofSize:weight:))) {
            method_exchangeImplementations(monospacedDigitSystemFontMethod, myMonospacedDigitSystemFontMethod)
        }
        
        if let monospacedSystemFontMethod = class_getClassMethod(self, #selector(monospacedSystemFont(ofSize:weight:))),
           let myMonospacedSystemFontMethod = class_getClassMethod(self, #selector(mySystemFont(ofSize:weight:))) {
            method_exchangeImplementations(monospacedSystemFontMethod, myMonospacedSystemFontMethod)
        }
        
        if let boldSystemFontMethod = class_getClassMethod(self, #selector(boldSystemFont(ofSize:))),
           let myBoldSystemFontMethod = class_getClassMethod(self, #selector(myBoldSystemFont(ofSize:))) {
            method_exchangeImplementations(boldSystemFontMethod, myBoldSystemFontMethod)
        }
        
        if let italicSystemFontMethod = class_getClassMethod(self, #selector(italicSystemFont(ofSize:))),
           let myItalicSystemFontMethod = class_getClassMethod(self, #selector(myItalicSystemFont(ofSize:))) {
            method_exchangeImplementations(italicSystemFontMethod, myItalicSystemFontMethod)
        }
        
        if let preferredFontMethod = class_getClassMethod(self, #selector(preferredFont(forTextStyle:))),
           let myPreferredFontFontMethod = class_getClassMethod(self, #selector(myPreferredFont(forTextStyle:))) {
            method_exchangeImplementations(preferredFontMethod, myPreferredFontFontMethod)
        }
        
        if let preferredFontMethod2 = class_getClassMethod(self, #selector(preferredFont(forTextStyle:compatibleWith:))),
           let myPreferredFontFontMethod2 = class_getClassMethod(self, #selector(myPreferredFont(forTextStyle:compatibleWith:))) {
            method_exchangeImplementations(preferredFontMethod2, myPreferredFontFontMethod2)
        }
        
        if let initCoderMethod = class_getInstanceMethod(self, #selector(UIFontDescriptor.init(coder:))), // Trick to get over the lack of UIFont.init(coder:))
           let myInitCoderMethod = class_getInstanceMethod(self, #selector(UIFont.init(myCoder:))) {
            method_exchangeImplementations(initCoderMethod, myInitCoderMethod)
        }
    }
}
