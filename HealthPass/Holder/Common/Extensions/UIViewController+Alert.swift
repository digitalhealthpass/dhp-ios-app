//
//  UIViewController+Alert.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

extension UIViewController {
    // ======================================================================
    // === Internal API =====================================================
    // ======================================================================
    
    // MARK:  Internal API -
    
    // MARK:  Internal Methods
    
    // MARK: - Alert Convenience Methods
    
    func showAlert(title: String?, message: String?, actions: [String], completion: ((_ index: Int) -> Void)? = nil, presentCompletion: (() -> Void)? = nil) {
        let alert = IBMAlertController(title: title, description: message, style: .alert)
        
        for (index, action) in actions.enumerated() {
            let action = IBMAlertAction(title: action, style: .default, action: {
                if completion != nil { completion!(index) }
            })
            
            alert.addAction(action)
        }
        
        present(alert, animated: true, completion: presentCompletion)
    }
    
    func showConfirmation(title: String?, message: String?, actions: [(String, IBMAlertActionStyle)], completion: ((_ index: Int) -> Void)? = nil, presentCompletion: (() -> Void)? = nil) {
        let alert = IBMAlertController(title: title, description: message, style: .alert)
        
        var keyedActions = [(Int, String, IBMAlertActionStyle)]()
        var sortedActions = [(Int, String, IBMAlertActionStyle)]()
        
        for (index, action) in actions.enumerated() {
            let keyedAction = (index, action.0, action.1)
            keyedActions.append(keyedAction)
        }
        
        sortedActions.append(contentsOf: keyedActions.filter( { $0.2 == .destructive } ))
        sortedActions.append(contentsOf: keyedActions.filter( { $0.2 == .cancel } ))
        sortedActions.append(contentsOf: keyedActions.filter( { $0.2 == .default } ))
        
        sortedActions.forEach { action in
            let index = action.0
            let title = action.1
            let style = action.2
            
            let alertAction = IBMAlertAction(title: title, style: style, action: {
                if completion != nil { completion!(index) }
            })
            
            alert.addAction(alertAction)
        }
        
        present(alert, animated: true, completion: presentCompletion)
    }
    
    func showPasswordAlert(title: String, message: String = "", buttonTitle: String, completion: @escaping (String) -> Void, presentCompletion: (() -> Void)? = nil) {
        let alert = IBMAlertController(title: title, description: message, style: .alert)
        
        alert.addTextField { (textField) in
            textField?.isSecureTextEntry = true
            textField?.placeholder = "label.placeholder.password".localized
        }
        
        alert.addAction(IBMAlertAction(title: buttonTitle, style: .default, action: {
            let password = alert.textFields.first?.text ?? ""
            completion(password)
        }))
        
        alert.addAction(IBMAlertAction(title: "button.title.cancel".localized, style: .cancel, action: nil))
        
        self.present(alert, animated: true, completion: presentCompletion)
    }
    
    func showActionSheet(title: String?, message: String?, actions: [(String, IBMAlertActionStyle)], completion: ((_ index: Int) -> Void)? = nil, presentCompletion: (() -> Void)? = nil) {
        let alert = IBMAlertController(title: title, description: message, style: UIResponder().isPhone ? .actionSheet : .alert)
        
        var keyedActions = [(Int, String, IBMAlertActionStyle)]()
        var sortedActions = [(Int, String, IBMAlertActionStyle)]()
        
        for (index, action) in actions.enumerated() {
            let keyedAction = (index, action.0, action.1)
            keyedActions.append(keyedAction)
        }
        
        sortedActions.append(contentsOf: keyedActions.filter( { $0.2 == .destructive } ))
        sortedActions.append(contentsOf: keyedActions.filter( { $0.2 == .cancel } ))
        sortedActions.append(contentsOf: keyedActions.filter( { $0.2 == .default } ))
        
        sortedActions.forEach { action in
            let index = action.0
            let title = action.1
            let style = action.2
            
            let alertAction = IBMAlertAction(title: title, style: style, action: {
                if completion != nil { completion!(index) }
            })
            
            alert.addAction(alertAction)
        }
        
        present(alert, animated: true, completion: presentCompletion)
    }
    
}
