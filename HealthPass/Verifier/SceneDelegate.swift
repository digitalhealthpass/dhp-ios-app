//
//  SceneDelegate.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    static let SessionTimeOutIdentifier = Notification.Name("SessionTimeOut")
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        showSplashScreenWindow()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        hideSplashScreenWindow()
    }

    // MARK: Show Splash Screen
    private var splashScreenWindow: UIWindow?

    private func showSplashScreenWindow() {
        guard let windowScene = self.window?.windowScene else { return }
        
        let storyboard = UIStoryboard(name: "SplashScreen", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "splashScreen")

        splashScreenWindow = UIWindow(windowScene: windowScene)
        splashScreenWindow?.rootViewController = controller
        splashScreenWindow?.windowLevel = .alert + 1
        splashScreenWindow?.makeKeyAndVisible()
    }

    private func hideSplashScreenWindow() {
        splashScreenWindow?.isHidden = true
        splashScreenWindow = nil
    }
}

extension SceneDelegate {
    
    public static func jailbroken(application: UIApplication) -> Bool {
        guard let cydiaUrlScheme = URL(string: "cydia://package/com.example.package") else { return isJailbroken() }
        return application.canOpenURL(cydiaUrlScheme) || isJailbroken()
    }
    
    
    static func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        /* added recommended IOSSecuiritySuite test for jailbreak as per
             78277: Jailbreak Detection Bypassed\
             IBM HealthPass - Q1 2021 Penetration Testing Report
             Detailed report for the API(s) and Mobile Application penetration
             testing performed by PTC for IBM HealthPass
             Date: Wed Mar 03 17:01:36 IST 2021
             Client Contact: Richard M Scott/Dallas/IBM@IBMUS, Brian Arffa/Westford/IBM Report Prepared By: Shukla, Pragun
        */
        let securitySuiteTestFlag = IOSSecuritySuite.amIJailbroken()
        if securitySuiteTestFlag == true {
            return true
        }
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: "/Applications/Cydia.app") ||
            fileManager.fileExists(atPath: "/Library/MobileSubstrate/MobileSubstrate.dylib") ||
            fileManager.fileExists(atPath: "/bin/bash") ||
            fileManager.fileExists(atPath: "/usr/sbin/sshd") ||
            fileManager.fileExists(atPath: "/etc/apt") ||
            fileManager.fileExists(atPath: "/usr/bin/ssh") {
            return true
        }
        
        if canOpen(path: "/Applications/Cydia.app") ||
            canOpen(path: "/Library/MobileSubstrate/MobileSubstrate.dylib") ||
            canOpen(path: "/bin/bash") ||
            canOpen(path: "/usr/sbin/sshd") ||
            canOpen(path: "/etc/apt") ||
            canOpen(path: "/usr/bin/ssh") {
            return true
        }
        
        let path = "/private/" + NSUUID().uuidString
        do {
            try "anyString".write(toFile: path, atomically: true, encoding: .utf8)
            try fileManager.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
        #endif
    }
    
    static func canOpen(path: String) -> Bool {
        let file = fopen(path, "r")
        guard file != nil else { return false }
        fclose(file)
        return true
    }
    
}

extension SceneDelegate {
    
    private func getTopViewController() -> UIViewController? {
        guard var topController = window?.rootViewController else {
            return nil
        }
        
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
    
}
