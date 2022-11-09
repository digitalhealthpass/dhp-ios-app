//
//  Bundle+Extension.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

extension Bundle {
    
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    
    var appVersionNumber: String? {
        guard let releaseVersionNumber = self.releaseVersionNumber, let buildVersionNumber = self.buildVersionNumber else { return nil }
        
        return String(format: "%@ (%@)", releaseVersionNumber, buildVersionNumber)
    }
    
}
