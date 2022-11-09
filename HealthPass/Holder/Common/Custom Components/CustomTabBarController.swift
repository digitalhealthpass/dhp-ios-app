//
//  CustomTabBarController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import QRCoder
import MobileCoreServices

class CustomTabbarController: UITabBarController {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setTabBarAttributes()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if HOLDER
        
        DataStore.shared.didLoadHomeController = true
        
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if HOLDER
        
        DataStore.shared.didLoadHomeController = true
        
        if let url = DataStore.shared.importURL, url.containsImage {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.prepareCardImageImport(url: url)
            }
        } else if let url = DataStore.shared.importURL, url.containsJSON {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.prepareCredentialFileImport(for: url)
            }
        } else if let url = DataStore.shared.importURL, url.containsSHC {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.prepareSHCFileImport(for: url)
            }
        } else if let url = DataStore.shared.importURL, url.containsArchive {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.prepareKeychainArchiveImport(for: url)
            }
        } else {
            handleDeeplink()
        }
        
        #endif
    }
    
    func setTabBarAttributes() { }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        generateSelectionFeedback()
    }
    
}
