//
//  UIViewController+ErrorHandle.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

import UIKit

extension UIViewController {
    func isCanceledError(error: Error) -> Bool {
        do {
            throw error
        } catch URLError.cancelled {
            return true
        } catch CocoaError.userCancelled {
            return true
        } catch {
            return false
        }
    }
    
    @objc @discardableResult
    func handleError(error: Error,
                     errorTitle: String? = nil,
                     errorMessage: String? = nil,
                     errorAction: String? = nil,
                     completion: (() -> Void)? = nil) -> Bool {
        generateNotificationFeedback(.error)
        
        guard !isCanceledError(error: error) else {
            return false
        }
        
        let err = error as NSError
        
        let errContent = err.getGenericErrorContent()
        let title = errorTitle ?? errContent.0 ?? String()
        var message = errorMessage ?? errContent.1 ?? err.localizedDescription
        let action = errorAction ?? NSLocalizedString("button.title.ok".localized, comment: "")
        
        let domain = err.domain.isEmpty ? "Domain=Unknown" : "Domain=\(err.domain)"
        let code = "Code=\(err.code)"
        
        message = message + String("\n\n(\(domain) | \(code))")
        
        
        if message.contains("_") {
            let messageWithoutUnderscore = message.replacingOccurrences(of: "_", with: " ")
            showConfirmation(title: title, message: messageWithoutUnderscore, actions: [(action, IBMAlertActionStyle.cancel)],
                             completion: { _ in
                                completion?()
                             })
        } else {
            showConfirmation(title: title, message: message, actions: [(action, IBMAlertActionStyle.cancel)],
                             completion: { _ in
                                completion?()
                             })
        }
        return true
    }
}
