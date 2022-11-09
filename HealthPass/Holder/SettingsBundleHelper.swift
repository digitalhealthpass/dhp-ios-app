//
//  SettingsBundleHelper.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

class SettingsBundleHelper {
    
    static let shared = SettingsBundleHelper()
    
    private init() {}
    
    var savedEnvironment: EnvTarget {
        get {
            guard let env = UserDefaults.standard.string(forKey: "savedEnvironment") else {
                self.savedEnvironment = EnvTarget.prod
                return EnvTarget.prod
            }
            
            guard let savedEnvironment = EnvTarget(rawValue: env.lowercased()), EnvTarget.debugEnv.contains(savedEnvironment) else {
                self.savedEnvironment = EnvTarget.prod
                return EnvTarget.prod
            }
            
            return savedEnvironment
        } set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "savedEnvironment")
        }
    }
}
