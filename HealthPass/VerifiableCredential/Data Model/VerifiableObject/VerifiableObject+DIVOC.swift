//
//  VerifiableObject+DIVOC.swift
//  VerifiableCredential
//
//  Created by Iryna Horbachova on 09.08.2021.
//

import Foundation
import OSLog
import Zip

extension VerifiableObject {
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Methods
    
    internal func isValidDIVOC(message: String) -> Bool {
        guard message.hasPrefix(DIVOCPREFIX) else {
            return false
        }
        return true
    }
    
    internal func parse(divoc: Data) -> String? {
        // Store credential data as DIVOCCredential.zip file on the system
        var zipURL: URL!
        do {
            let documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            zipURL = documentsDirectory.appendingPathComponent("DIVOCCredential.zip")
            try divoc.write(to: zipURL)
        } catch {
            os_log("[FAIL] - DIVOC - writing to file failed", log: OSLog.verifiableObjectOSLog)
            return nil
        }
        // Unzip stored data
        // Return contents of certificate.json file from the archive as string
        do {
            let unzipDirectoryURL = try Zip.quickUnzipFile(zipURL)
            let certificateURL = unzipDirectoryURL.appendingPathComponent("certificate.json")
            let certificateString = try String(contentsOf: certificateURL, encoding: .utf8)
            // Remove created files
            try FileManager.default.removeItem(at: zipURL)
            try FileManager.default.removeItem(at: unzipDirectoryURL)
            
            os_log("[SUCCESS] - Parsed DIVOC certificate: %@", certificateString)
            return certificateString
        }
        catch {
            os_log("[FAIL] - DIVOC - unzip failed", log: OSLog.verifiableObjectOSLog)
            return nil
        }
    }
}
