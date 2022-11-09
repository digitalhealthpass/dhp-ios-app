//
//  AppDelegate.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import os.log
@_exported import VerifiableCredential

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    override init() {
        super.init()
    
        setUserDefaults()
        
        UIFont.overrideInitialize()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.ignoreSnapshotOnNextApplicationLaunch()
        return true
    }
    
    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        return !(extensionPointIdentifier == UIApplication.ExtensionPointIdentifier.keyboard)
    }
    
    // MARK: - UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    private func setUserDefaults() {
        UserDefaults.standard.register(defaults: [UserDefaultsKey.kRevocationVerification.rawValue : true])
        
        UserDefaults.standard.register(defaults: [UserDefaultsKey.kKioskMode.rawValue : (UIDevice.current.userInterfaceIdiom == .pad)])
        UserDefaults.standard.register(defaults: [UserDefaultsKey.kFrontCamera.rawValue : false])
        UserDefaults.standard.register(defaults: [UserDefaultsKey.kAlwaysDismiss.rawValue : true])
        UserDefaults.standard.register(defaults: [UserDefaultsKey.kDismissDuration.rawValue : 5])
        
        UserDefaults.standard.register(defaults: [UserDefaultsKey.kHapticFeedback.rawValue : true])
        UserDefaults.standard.register(defaults: [UserDefaultsKey.kSoundFeedback.rawValue : true])

    }
}

extension OSLog {
    static var subsystem = Bundle.main.bundleIdentifier ?? String("com.ibm.watson.healthpass.verify")
}
