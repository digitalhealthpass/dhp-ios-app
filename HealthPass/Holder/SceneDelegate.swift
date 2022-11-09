//
//  SceneDelegate.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

enum DeeplinkAction: String {
    //IMPORT
    
    case importContactJSON = "importContactJSON"
    case importCredentialImage = "importCredentialImage"
    case importCredentialFile = "importCredentialFile"
    
    //DEEPLINK
    
    //dhpwallet://open.dhpwallet.app/generatekey
    case generateKey = "generatekey"
    
    //dhpwallet://open.dhpwallet.app/registration?org=hit&code=242f5095-5554-40a8-b6ea-36014b128cf5
    case registration = "registration"
    
    //dhpwallet://open.dhpwallet.app/download?cred=vc-0b8f0fa0-5c18-4fd4-8775-4ca41f3cdab5
    case download = "download"

    //dhpwallet://open.dhpwallet.app/credential?data=eyJAY29udGV4dCI6WyJodHRwczovL3d3dy53My5vcmcvMjAxOC9jcmVkZW50aWFscy92MSJdLCJjcmVkZW50aWFsU2NoZW1hIjp7ImlkIjoiZGlkOmhwYXNzOjE5YjBjZjBkNWZjNzAxN2RkNjZkZGQyMzc0ZmJkOWI3OTZkOTg4YWNlZDA4M2Q3MDlhYmJhYTBmNzQ4MGI0NzQ6YzRkMTQ5MmU4MWJmY2I5NTFkMDI4YzBhNGJkM2MxZWRlYzE2ZDMyYWVkNzdhNjA4Yzc2ZWQ5MTdmMzIzMWY3ZTtpZD12YWNjaW5hdGlvbmNhcmQ7dmVyc2lvbj0wLjIiLCJ0eXBlIjoiSnNvblNjaGVtYVZhbGlkYXRvcjIwMTgifSwiY3JlZGVudGlhbFN1YmplY3QiOnsiZGlzcGxheSI6ImdyZWVuIiwiaGlzdG9yeSI6W3sibG90TnVtYmVyIjoiNjc5ODkwIiwibWFudWZhY3R1cmVyIjoiUEZpemVyIiwib2NjdXJyZW5jZURhdGVUaW1lIjoiMjAyMC0xMi0wOCIsInZhY2NpbmUiOiJQZml6ZXItQmlvbnRlY2ggQ292aWQtMTkgVmFjY2luZSIsInZhY2NpbmVDb2RlIjoiMDAwMUEifV0sImxvdE51bWJlciI6IjEyMzQ1IiwibWFudWZhY3R1cmVyIjoiUEZpemVyIiwib2NjdXJyZW5jZURhdGVUaW1lIjoiMjAyMC0xMi0zMCIsInN0YXR1cyI6ImNvbXBsZXRlZCIsInN1YmplY3QiOnsiYWRkcmVzcyI6IiIsImJpcnRoRGF0ZSI6IjIwMDAtMTAtMTAiLCJlbWFpbCI6IiIsImdlbmRlciI6ImZlbWFsZSIsImlkZW50aXR5IjpbeyJzeXN0ZW0iOiJ0cmF2ZWwuc3RhdGUuZ292IiwidHlwZSI6IlBQTiIsInZhbHVlIjoiQVAxMjM0NUYifV0sIm5hbWUiOnsiZmFtaWx5IjoiU21pdGgiLCJnaXZlbiI6IkphbmUifSwicGhvbmUiOiIifSwidGFyZ2V0RGlzZWFzZSI6IkNvdmlkLTE5IiwidHlwZSI6IlZhY2NpbmF0aW9uIENhcmQiLCJ2YWNjaW5lIjoiUGZpemVyLUJpb250ZWNoIENvdmlkLTE5IFZhY2NpbmUiLCJ2YWNjaW5lQ29kZSI6IjAwMDJBIn0sImV4cGlyYXRpb25EYXRlIjoiMjAyMS0xMi0wN1QwMDowMDowMFoiLCJpZCI6ImRpZDpocGFzczoxOWIwY2YwZDVmYzcwMTdkZDY2ZGRkMjM3NGZiZDliNzk2ZDk4OGFjZWQwODNkNzA5YWJiYWEwZjc0ODBiNDc0OjdlNTU5NjZjMjM1NjNhOTY1YjYzODM0YjUzYWVhMTk2ZDE0Yjg2NTQyMDhjZWMyYjUxYWI2ZjlmMGY2Y2I2MjMjdmMtNTFhMDdjMTQtNmVlZC00ZGQwLTkwNTktMzhhMTQ5YjRiZTlkIiwiaXNzdWFuY2VEYXRlIjoiMjAyMS0wMi0wOVQyMzo0ODoyMVoiLCJpc3N1ZXIiOiJkaWQ6aHBhc3M6MTliMGNmMGQ1ZmM3MDE3ZGQ2NmRkZDIzNzRmYmQ5Yjc5NmQ5ODhhY2VkMDgzZDcwOWFiYmFhMGY3NDgwYjQ3NDo3ZTU1OTY2YzIzNTYzYTk2NWI2MzgzNGI1M2FlYTE5NmQxNGI4NjU0MjA4Y2VjMmI1MWFiNmY5ZjBmNmNiNjIzIiwicHJvb2YiOnsiY3JlYXRlZCI6IjIwMjEtMDItMDlUMjM6NDg6MjFaIiwiY3JlYXRvciI6ImRpZDpocGFzczoxOWIwY2YwZDVmYzcwMTdkZDY2ZGRkMjM3NGZiZDliNzk2ZDk4OGFjZWQwODNkNzA5YWJiYWEwZjc0ODBiNDc0OjdlNTU5NjZjMjM1NjNhOTY1YjYzODM0YjUzYWVhMTk2ZDE0Yjg2NTQyMDhjZWMyYjUxYWI2ZjlmMGY2Y2I2MjMja2V5LTEiLCJub25jZSI6ImFjZmVjMWI4LThlYjQtNDQ5Yi1iOWM0LWVjYTIxZDJhMjUwOSIsInNpZ25hdHVyZVZhbHVlIjoiTUVRQ0lEY3hoWXZUQk5RUjI4OFpsN3B5VzZTLUZWQ2k3aWFfOXFHZnlucThZUGZGQWlBYXdiUmdsbjdYSHRqQ3J3azY1VnBFMVFDUmNWUURPeHlSMUl5RV9NeTNFQSIsInR5cGUiOiJFY2RzYVNlY3AyNTZyMVNpZ25hdHVyZTIwMTkifSwidHlwZSI6WyJWZXJpZmlhYmxlQ3JlZGVudGlhbCJdfQ==
    case credential = "credential"
}

enum DeeplinkParameters: String {
    case accessCode = "accesscode"
    
    case organization = "organization"
    case registrationCode = "registrationCode"
    
    case cred = "cred"

    case org = "org"
    case code = "code"
    
    case data = "data"
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let url = connectionOptions.urlContexts.first?.url {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                self.handleHandoff(for: url)
            }
        }
        
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
    
    func scene( _ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext> ) {
        guard let url = URLContexts.first?.url else {
            return
        }
        
        handleHandoff(for: url)
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
    
    // MARK: - Helper Methods
    
    internal func getTopViewController() -> UIViewController? {
        guard var topController = window?.rootViewController else {
            return nil
        }
        
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
    
    // MARK: - Handoff Methods
    
    private func handleHandoff(for url: URL) {
        DataStore.shared.importURL = url

        if url.containsImage {
            self.prepareCardImageImport(for: url)
        } else if url.containsJSON   {
            self.prepareCredentialFileImport(for: url)
        } else if url.containsSHC {
            self.prepareSHCFileImport(for: url)
        }else if url.containsArchive {
            self.prepareKeychainArchiveImport(for: url)
        } else {
            handleDeeplink(url: url)
        }
    }
}
