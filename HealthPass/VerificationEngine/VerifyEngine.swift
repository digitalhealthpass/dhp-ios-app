//
//  VerificationEngine.swift
//  VerificationEngine
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import VerifiableCredential
import OSLog

extension OSLog {
    static var subsystem = Bundle.main.bundleIdentifier ?? String("com.IBM.VerificationEngine")
    static let VerifyEngineOSLog = OSLog(subsystem: subsystem, category: "VerifiableObject")
}

/**
 
 A collection of helper functions for validating VerifiableObject..
 
 */
public class VerifyEngine {
  
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: Public Properties

    var verifiableObject: VerifiableObject?
    
    public var issuer: Issuer?
    public var jwkSet: [JWK]?
    public var issuerKeys: [IssuerKey]?

    // MARK: Public Methods

    public init() { }
    
    public init(verifiableObject: VerifiableObject) {
        self.verifiableObject = verifiableObject
    }
    
}

