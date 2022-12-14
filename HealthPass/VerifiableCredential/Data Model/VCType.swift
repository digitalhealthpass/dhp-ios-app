//
//  VCType.swift
//  VerifiableCredential
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

/// Enum representing supported types of Verifiable Object. 
public enum VCType: String, Codable {
    case VC = "Verifiable Credential"
    
    case SHC = "smarthealth.cards"
    case IDHP = "IBMDigitalHealthPass"
    case DIVOC = "DIVOC"
    case DCC = "EU DCC"
    case GHP = "GoodHealthPass"
    
    case unknown = "unknown"
    
    public var keyId: String {
        switch self {
        case .VC: return "VC"
        
        case .SHC: return "SHC"
        case .IDHP: return "IDHP"
        case .DIVOC: return "DIVOC"
        case .DCC: return "DCC"
        case .GHP: return "GHP"
            
        case .unknown: return "unknown"
        }
    }
    
    public var displayValue: String {
        switch self {
        case .VC: return "Verifiable Credential"
        case .IDHP: return "IBM Digital Health Pass"
        case .SHC: return "SMART® Health Card"
        case .DIVOC: return "DIVOC's India Cowin"
        case .DCC: return "EU Digital COVID Certificate"
        case .GHP: return "GOOD HEALTH PASS"
            
        case .unknown: return "unknown"
        }
    }
    
}
