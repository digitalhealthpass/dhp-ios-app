//
//  IBMAlertAction.swift
//  Holder
//
//  Created by Gautham Velappan on 10/8/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

@objc public enum IBMAlertActionStyle : Int {
    
    case `default`
    case cancel
    case destructive
}

@objc open class IBMAlertAction: UIButton {
    
    fileprivate var action: (() -> Void)?
    
    open var actionStyle : IBMAlertActionStyle
    
    open var separator = UIImageView()
    
    init(){
        self.actionStyle = .cancel
        super.init(frame: CGRect.zero)
    }
    
    @objc public convenience init(title: String?, style: IBMAlertActionStyle, action: (() -> Void)? = nil){
        self.init()
        
        self.action = action
        self.addTarget(self, action: #selector(IBMAlertAction.tapped(_:)), for: .touchUpInside)
        
        self.contentVerticalAlignment = .top
        self.contentHorizontalAlignment = .left
        
        self.contentEdgeInsets = UIEdgeInsets(top: 16, left: 13, bottom: 0, right: 0)

        self.setTitle(title, for: UIControl.State())
        self.titleLabel?.font = AppFont.bodyScaled
        self.setTitleColor(.white, for: UIControl.State())
        
        self.actionStyle = style
        
        if style == .default {
            self.backgroundColor = UIColor(hex: "#0F62FE")
        } else if style == .cancel {
            self.backgroundColor = UIColor(hex: "#393939")
        } else if style == .destructive {
            self.backgroundColor = .systemRed
        }
        
        self.addSeparator()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapped(_ sender: IBMAlertAction) {
        //Action need to be fired after alert dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.action?()
        }
    }
    
    @objc fileprivate func addSeparator(){
        separator.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        self.addSubview(separator)
        
        // Autolayout separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        separator.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor, constant: 8).isActive = true
        separator.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor, constant: -8).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
}
