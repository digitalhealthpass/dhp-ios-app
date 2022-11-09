//
//  IBMAlertController.swift
//  Holder
//
//  Created by Gautham Velappan on 10/8/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

@IBDesignable class PaddingLabel: UILabel {
    
    @IBInspectable var topInset: CGFloat = CGFloat.zero
    @IBInspectable var bottomInset: CGFloat = CGFloat.zero
    @IBInspectable var leftInset: CGFloat = CGFloat.zero
    @IBInspectable var rightInset: CGFloat = CGFloat.zero
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftInset + rightInset,
                      height: size.height + topInset + bottomInset)
    }
    
    override var bounds: CGRect {
        didSet {
            // ensures this works within stack views if multi-line
            preferredMaxLayoutWidth = bounds.width - (leftInset + rightInset)
        }
    }
}

@objc public enum IBMAlertControllerStyle : Int {
    
    case alert
    case actionSheet
    
}

@objc open class IBMAlertController: UIViewController {
    
    // MARK: Properties
    @IBOutlet weak open var alertMaskBackground: UIImageView!
    @IBOutlet weak open var alertView: UIView!
    @IBOutlet weak open var alertViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak open var alertViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak open var alertViewCenterYConstraint: NSLayoutConstraint!
    
    @IBOutlet weak open var alertContentStackView: UIStackView!
    @IBOutlet weak open var alertTitle: UILabel!
    @IBOutlet weak open var alertDescription: UILabel!
    
    @IBOutlet weak open var alertContentStackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak open var alertContentStackViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak open var alertActionStackView: UIStackView!
    @IBOutlet weak open var cancelActionStackView: UIStackView!
    
    @IBOutlet weak open var alertActionStackViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak open var alertActionStackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak open var alertActionStackViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak open var alertActionStackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak open var alertActionStackViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak open var cancelActionStackViewHeightConstraint: NSLayoutConstraint!
    
    open var ALERT_STACK_VIEW_HEIGHT : CGFloat = UIScreen.main.bounds.height < 568.0 ? 40 : 72 //if iphone 4 the stack_view_height is 40, else 62
    var animator : UIDynamicAnimator?
    
    @objc open var textFields: [UITextField] = []
    
    @objc open var dismissWithBackgroudTouch = false // enable touch background to dismiss. Off by default.
    
    private var style: IBMAlertControllerStyle = .alert
    
    //MARK: - Lifecycle
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    //MARK: - Initialiser
    @objc public convenience init(title: String?, description: String?, style: IBMAlertControllerStyle) {
        self.init()
        
        guard let nib = loadNibAlertController(), let unwrappedView = nib[0] as? UIView else { return }
        self.view = unwrappedView
        
        alertActionStackViewHeightConstraint.constant = 0
        cancelActionStackViewHeightConstraint.constant = 0

        self.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        
        self.style = style
        
        alertTitle.font = AppFont.title3Scaled
        alertTitle.textColor = UIColor.alertTextColor
        if let title = title {
            alertTitle.text = title
        } else {
            alertTitle.isHidden = true
        }
        
        alertDescription.font = AppFont.calloutScaled
        alertDescription.textColor = UIColor.alertTextColor
        if let description = description {
            alertDescription.text = description
        } else {
            alertDescription.isHidden = true
        }
        
        let maxWidth = CGFloat(352.0)
        if style == .alert {
            let calculatedWidth = UIScreen.main.bounds.width - 64
            alertViewWidthConstraint.constant = calculatedWidth > maxWidth ? maxWidth : calculatedWidth
            alertViewBottomConstraint.priority = .defaultLow
            alertViewCenterYConstraint.priority = .required
            
            dismissWithBackgroudTouch = false
        } else if style == .actionSheet {
            let calculatedWidth = UIScreen.main.bounds.width - 16
            alertViewWidthConstraint.constant = calculatedWidth
            alertViewBottomConstraint.priority = .required
            alertViewCenterYConstraint.priority = .defaultLow
            
            dismissWithBackgroudTouch = true
        }
        
        //Gesture recognizer for background dismiss with background touch
        let tapRecognizer: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(dismissAlertControllerFromBackgroundTap))
        alertMaskBackground.addGestureRecognizer(tapRecognizer)
    }
    
    //MARK: - Actions
    @objc open func addAction(_ alertAction: IBMAlertAction) {
        if style == .alert {
            alertActionStackView.addArrangedSubview(alertAction)
        } else if style == .actionSheet {
            if alertAction.actionStyle == .cancel {
                cancelActionStackView.addArrangedSubview(alertAction)
                cancelActionStackViewHeightConstraint.constant = ALERT_STACK_VIEW_HEIGHT
            } else {
                alertActionStackView.addArrangedSubview(alertAction)
            }
        }
        
        if (style == .actionSheet) || (alertActionStackView.arrangedSubviews.count > 2) || hasTextFieldAdded() {
            alertActionStackViewHeightConstraint.constant = ALERT_STACK_VIEW_HEIGHT * CGFloat(alertActionStackView.arrangedSubviews.count)
            
            alertActionStackView.axis = .vertical
        } else {
            cancelActionStackViewHeightConstraint.constant = 0
            
            alertActionStackViewHeightConstraint.constant = ALERT_STACK_VIEW_HEIGHT
            alertActionStackView.axis = .horizontal
        }
        
        alertAction.addTarget(self, action: #selector(IBMAlertController.dismissAlertController(_:)), for: .touchUpInside)
    }
    
    @objc fileprivate func dismissAlertController(_ sender: IBMAlertAction) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func dismissAlertControllerFromBackgroundTap() {
        guard dismissWithBackgroudTouch else { return }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Text Fields
    @objc open func addTextField(textField:UITextField? = nil, _ configuration: (_ textField: UITextField?) -> Void) {
        let textField = textField ?? UITextField()
        textField.delegate = self
        
        textField.returnKeyType = .done
        textField.font = AppFont.bodyScaled
        textField.textAlignment = .center
        textField.borderStyle = .none
        textField.backgroundColor = .systemBackground
        
        configuration (textField)
        _addTextField(textField)
    }
    
    func _addTextField(_ textField: UITextField) {
        alertActionStackView.addArrangedSubview(textField)
        alertActionStackViewHeightConstraint.constant = ALERT_STACK_VIEW_HEIGHT * CGFloat(alertActionStackView.arrangedSubviews.count)
        alertActionStackView.axis = .vertical
        
        textFields.append(textField)
    }
    
    func hasTextFieldAdded () -> Bool {
        return textFields.count > 0
    }
    
    //MARK: - Customizations
    
    @objc fileprivate func loadNibAlertController() -> [AnyObject]? {
        let podBundle = Bundle(for: self.classForCoder)
        
        if let bundleURL = podBundle.url(forResource: "IBMAlertController", withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                return bundle.loadNibNamed("IBMAlertController", owner: self, options: nil) as [AnyObject]?
            } else {
                assertionFailure("Could not load the bundle")
            }
        } else if let nib = podBundle.loadNibNamed("IBMAlertController", owner: self, options: nil) as [AnyObject]? {
            return nib
        } else {
            assertionFailure("Could not create a path to the bundle")
        }
        
        return nil
    }
    
    //MARK: - Keyboard avoiding
    
    var tempFrameOrigin: CGPoint?
    var keyboardHasBeenShown:Bool = false
    
    @objc func keyboardWillShow(_ notification: Notification) {
        keyboardHasBeenShown = true
        
        guard let userInfo = (notification as NSNotification).userInfo else { return }
        guard let endKeyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.minY else { return }
        
        if tempFrameOrigin == nil {
            tempFrameOrigin = alertView.frame.origin
        }
        
        var newContentViewFrameY = alertView.frame.maxY - endKeyBoardFrame
        if newContentViewFrameY < 0 {
            newContentViewFrameY = 0
        }
        
        alertView.frame.origin.y -= newContentViewFrameY
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if (keyboardHasBeenShown) { // Only on the simulator (keyboard will be hidden)
            if (tempFrameOrigin != nil){
                alertView.frame.origin.y = tempFrameOrigin!.y
                tempFrameOrigin = nil
            }
            
            keyboardHasBeenShown = false
        }
    }
    
}

extension IBMAlertController: UITextFieldDelegate {
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
}

extension UIColor {
    
    static var alertTextColor: UIColor {
        return UIColor { (traits) -> UIColor in
            return traits.userInterfaceStyle == .dark ? UIColor.white : (UIColor(hex: "#161616") ?? UIColor.black)
        }
    }
    
}
