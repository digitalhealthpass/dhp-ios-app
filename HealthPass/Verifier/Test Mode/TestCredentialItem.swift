//
//  TestCredentialItem.swift
//  Verifier
//
//  Created by John Martino on 2021-09-13.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit
import VerifiableCredential

enum TestCredentialStatus {
    case untested
    case testing
    case success
    case failure
    
    var displayValue: String {
        switch self {
        case .untested: return "Ready to Test"
        case .testing: return "Testing"
        case .success: return "Verified"
        case .failure: return "Not Verified"
        }
    }
    
    var tint: UIColor {
        switch self {
        case .untested: return .systemGray
        case .testing: return .systemYellow
        case .success: return .systemGreen
        case .failure: return .systemRed
        }
    }
    
    var seal: String {
        switch self {
        case .untested: return ""
        case .testing: return "clock.fill"
        case .success: return "checkmark.circle.fill"
        case .failure: return "multiply.circle.fill"
        }
    }
}

struct TestCredentialItem {
    let verifiableObject: VerifiableObject
    let image: UIImage
    let imageName: String?
    var status: TestCredentialStatus
    var errorMessage: String?
}
