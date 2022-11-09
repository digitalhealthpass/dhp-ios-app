//
//  URL+type.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import MobileCoreServices

extension URL {
    
    var mimeType: String? {
        guard let uti = uti else {
            return nil
        }
        
        guard let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() else {
            return nil
        }
        
        return mimetype as String
    }
    
    var uti: CFString? {
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() else {
            return nil
        }
        
        return uti
    }
    
    var containsImage: Bool {
        guard let uti = uti else {
            return false
        }
        
        return UTTypeConformsTo(uti, kUTTypeImage)
    }
    
    var containsArchive: Bool {
        guard let uti = uti else {
            return false
        }
        
        return UTTypeConformsTo(uti, kUTTypeGNUZipArchive) || UTTypeConformsTo(uti, kUTTypeData)
    }
    
    var containsJSON: Bool {
        guard let uti = uti else {
            return false
        }
        
        return UTTypeConformsTo(uti, kUTTypeJSON)
    }
    
    var containsSHC: Bool {
        guard let uti = uti else {
            return false
        }
        
        return UTTypeConformsTo(uti, kUTTypeData)
    }
}
