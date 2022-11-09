//
//  SceneDelegate+UserNotifications.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UserNotifications

extension SceneDelegate: UNUserNotificationCenterDelegate {
    
    func scheduleSessionNotification(timeInterval: TimeInterval) {
        invalidateSessionTimer(withIdentifiers: [UserNotificationsCategoryIdentifier.sessionTimeout.rawValue])
    }
    
    @objc
    func sessionExpirySelector() {
        DataStore.shared.resetUserLogin()
    }
    
    // called when user interacts with notification (app not running in foreground)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        return completionHandler()
    }
    
    // called if app is running in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let categoryIdentifier = notification.request.content.categoryIdentifier
        let userNotificationsCategoryIdentifier = UserNotificationsCategoryIdentifier(rawValue: categoryIdentifier) ?? UserNotificationsCategoryIdentifier.unknown
        
        if userNotificationsCategoryIdentifier == .sessionTimeout {
            sessionExpirySelector()
        }
        
        if #available(iOS 14.0, *) {
            return completionHandler(.banner)
        }
        return completionHandler(.alert)
    }
}
