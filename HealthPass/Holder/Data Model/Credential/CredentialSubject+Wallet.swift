//
//  CredentialSubject+Wallet.swift
//  Holder
//
//  Created by Gautham Velappan on 8/20/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit

extension CredentialSubject {
    
    func getColor() -> UIColor {
        guard let display = (rawDictionary?["display"] as? String)?.lowercased() else {
            return UIColor.black
        }
        
        if let hexColor = UIColor(hex: display) {
            return hexColor
        }
        
        if display.contains("red") {
            return UIColor.systemRed
        } else if display.contains("green") {
            return UIColor.systemGreen
        } else if display.contains("blue") {
            return UIColor.systemBlue
        } else if display.contains("orange") {
            return UIColor.systemOrange
        }
        
        return UIColor.black
    }
    
}
