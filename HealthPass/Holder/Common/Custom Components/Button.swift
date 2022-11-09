//
//  Button.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class Button: UIButton {
    
    var contentSizeCategoryObserver: NSObjectProtocol!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        titleLabel?.adjustsFontForContentSizeCategory = true
        contentSizeCategoryObserver = NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification,
                                                                             object: nil, queue: .main) { [unowned self] notification in
                                                                                self.setNeedsLayout()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(contentSizeCategoryObserver!)
    }
}

class PlatterButton: Button {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.cornerRadius = 5.0
        layer.cornerCurve = .continuous
        layer.borderWidth = 1.0
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = max(size.height, 50.0)
        return size
    }
    
    override func tintColorDidChange() {
        setNeedsLayout()
    }
    
    @IBInspectable var isProminent: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel?.adjustsFontSizeToFitWidth = true
        
        if isProminent {
            backgroundColor = tintColor.withAlphaComponent(isEnabled ? 1.0 : 0.4)
            setTitleColor(.white, for: .normal)
            layer.borderColor = backgroundColor?.cgColor
        } else {
            backgroundColor = .clear
            setTitleColor(.white, for: .normal)
            layer.borderColor = UIColor.white.cgColor
        }
    }
}
