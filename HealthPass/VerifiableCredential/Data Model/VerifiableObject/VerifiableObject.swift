//
//  VerifiableObject.swift
//  VerifiableObject
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import OSLog
import SwiftCBOR

extension OSLog {
    static var subsystem = Bundle.main.bundleIdentifier ?? String("com.IBM.VerifiableCredential")
    static let verifiableObjectOSLog = OSLog(subsystem: subsystem, category: "VerifiableObject")
}

public struct VerifiableObject {
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Properties
    
    public var jws: JWS?
    public var cose: Cose?
    public var credential: Credential?
    
    public var type: VCType
    
    public var rawString: String?
    public var rawData: Data?
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Properties
    
    // Prefixes used in the beginning of credential strings
    internal let HC1PREFIX = "HC1:"
    internal let SHCPREFIX = "shc:/"
    internal let DIVOCPREFIX = "PK"
}

extension VerifiableObject {
    
    // MARK: - Initializer
    
    public init(string: String) {
        rawString = string
        
        jws = nil
        cose = nil
        credential = nil
        type = VCType.unknown
        
        if isValidSHC(message: string), let vciString = try? parse(shc: string),
           isValidJWS(message: vciString), let vciJWS = getJWS(for: vciString) { //smarthealth.cards
            jws = vciJWS
            type = VCType.SHC
        } else if isValidHC1(message: string), let euCose = try? parse(hc1: string) { // EU DCC
            cose = euCose
            type = VCType.DCC
        } else if isValidCredential(messages: string) { // IBMDigitalHealthPass or GoodHealthPass
            credential = getCredential(messages: string)
            type = getCredentialType(for: credential)
        }
        
        os_log("%{public}@", log: OSLog.verifiableObjectOSLog, type: .info, "\(type.rawValue) = \(String(describing: rawString))")
        
    }
    
    public init(data: Data) {
        rawData = data
        
        jws = nil
        cose = nil
        credential = nil
        type = VCType.unknown
        
        if let vciString = try? parse(jwsRepresentation: data),
           isValidJWS(message: vciString), let vciJWS = getJWS(for: vciString) { //smarthealth.cards
            rawString = try? shcRepresentation(for: data)
            
            jws = vciJWS
            type = VCType.SHC
            
        } else if let message = String(data: data, encoding: .ascii), isValidDIVOC(message: message), let divoc = parse(divoc: data) {
            credential = getCredential(messages: divoc)
            type = .DIVOC
        }
        
        os_log("%{public}@", log: OSLog.verifiableObjectOSLog, type: .info, "\(type.rawValue) = \(String(describing: rawString))")
        
    }
    
}

extension VerifiableObject {
    
    public var payload: Any? {
        switch type {
        case .SHC:
            guard let payloadData = jws?.payloadData else {
                return nil
            }
            
            guard let payload = try? JSONSerialization.jsonObject(with: payloadData, options: []) else {
                return nil
            }
            
            return payload
            
        case .IDHP, .GHP, .DIVOC, .VC:
            guard let payload = credential?.rawDictionary else {
                return nil
            }
            
            return payload
            
        case .DCC:
            guard let objectCBOR = cose?.payload.decodeBytestring() else {
                return nil
            }
            
            guard let objectMap = objectCBOR.asMap() else {
                return nil
            }
            
            guard let filteredMap = objectMap[-260]?.asMap() ?? objectMap[-259]?.asMap() else {
                return nil
            }
            
            guard let filteredCBOR = filteredMap[1] else {
                return nil
            }
            
            guard let payload = filteredCBOR.asMap() else {
                return nil
            }
            
            return CBOR.decodeDictionary(payload)
            
        case .unknown:
            return nil
            
        }
    }
    
    public var uploadData: Any? {
        switch type {
        case .IDHP, .GHP, .DIVOC, .VC:
            return credential?.rawDictionary
            
        case .SHC:
            guard let shc = rawString else {
                return nil
            }
            
            return try? parse(shc: shc)
        case .DCC:
            return rawString
        default:
            return nil
            
        }
    }
    
    public var uploadIdentifier: String? {
        switch type {
        case .IDHP, .GHP, .DIVOC, .VC:
            return credential?.id
            
        case .SHC:
            guard let nbf = jws?.payload?.nbf else {
                return nil
            }
            
            return String(describing: nbf)
        case .DCC:
            guard let cose = cose,
                  let cwt = CWT(from: cose.payload),
                  let certificateIdentifier = cwt.euHealthCert?.vaccinations?.first?.certificateIdentifier ?? cwt.euHealthCert?.recovery?.first?.certificateIdentifier ?? cwt.euHealthCert?.tests?.first?.certificateIdentifier else {
                      return nil
                  }
            return String(describing: certificateIdentifier)
        default:
            return nil
            
        }
    }
}

/**
 A collection of helper functions for creating JSON Decoder/Encoder
 */

public func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

public func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}
