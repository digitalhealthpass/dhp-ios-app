//
//  Toast.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class Toast: UIView, NibLoadable {
    @IBOutlet var glyph: UIImageView!
    @IBOutlet var label: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }
    
    func sharedInit() {
        clipsToBounds = false
        let contentView = loadViewFromNib()
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        
        glyph?.tintColor = .label
        label?.textColor = .label
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let superview = superview else { return }
        let length = min(superview.bounds.width / 2, 375)
        bounds = CGRect(x: 0, y: 0, width: length, height: length)
        layer.position = CGPoint(x: superview.bounds.width / 2, y: superview.bounds.height / 2)
    }
}

/// A protocol for objects which help load nib files matching the class name.
protocol NibLoadable {
    func loadViewFromNib(nibName: String?) -> UIView
}


extension NibLoadable where Self: UIView {
    /// By default, load the nib matching class name. The nib must be located in the same bundle as the class.
    func loadViewFromNib(nibName: String? = nil) -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nibName = nibName ?? String(describing: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }
}
