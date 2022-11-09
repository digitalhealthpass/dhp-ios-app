//
//  Payload.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

public struct JWSPayload: Codable {
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Properties
    
    /**
     The iss (issuer) claim has the same meaning and processing rules as the iss claim defined in Section 4.1.1 of [RFC7519], except that the value is a StringOrURI, as defined in Section 2 of this specification. The Claim Key 1 is used to identify this claim.
     */
    public var iss: String?
    
    /**
     The sub (subject) claim has the same meaning and processing rules as the sub claim defined in Section 4.1.2 of [RFC7519], except that the value is a StringOrURI, as defined in Section 2 of this specification. The Claim Key 2 is used to identify this claim.
     */
    public var sub: String?
    
    /**
     The aud (audience) claim has the same meaning and processing rules as the aud claim defined in Section 4.1.3 of [RFC7519], except that the value of the audience claim is a StringOrURI when it is not an array or each of the audience array element values is a StringOrURI when the audience claim value is an array. (StringOrURI is defined in Section 2 of this specification.) The Claim Key 3 is used to identify this claim.
     */
    public var aud: String?
    
    /**
     The exp (expiration time) claim has the same meaning and processing rules as the exp claim defined in Section 4.1.4 of [RFC7519], except that the value is a NumericDate, as defined in Section 2 of this specification. The Claim Key 4 is used to identify this claim.
     */
    public var exp: UInt64?

    /**
     The nbf (not before) claim has the same meaning and processing rules as the nbf claim defined in Section 4.1.5 of [RFC7519], except that the value is a NumericDate, as defined in Section 2 of this specification. The Claim Key 5 is used to identify this claim.
     */
    public var nbf: UInt64?

    /**
     The iat (issued at) claim has the same meaning and processing rules as the iat claim defined in Section 4.1.6 of [RFC7519], except that the value is a NumericDate, as defined in Section 2 of this specification. The Claim Key 6 is used to identify this claim.
     */
    public var iat: UInt64?

    /**
     The cti (CWT ID) claim has the same meaning and processing rules as the jti claim defined in Section 4.1.7 of [RFC7519], except that the value is a byte string. The Claim Key 7 is used to identify this claim.
     */
    public var cti: Data?

    /**
     jti MUST represent the id property of the verifiable credential or verifiable presentation.
     */
    public var jti: String?
    
    public var nonce: String?
    
    public var vc: Credential?
    
    enum PayloadKeys : Int {
        
        case iss = 1
        case sub = 2
        case aud = 3
        case exp = 4
        case nbf = 5
        case iat = 6
        
        case cti = 7
      
        case jti = -1
        case nonce = -2

    }
    
    enum PayloadKeyStrings : String {
        
        case iss = "iss"
        case sub = "sub"
        case aud = "aud"
        case exp = "exp"
        case nbf = "nbf"
        case iat = "iat"
        
        case cti = "cti"
        
        case jti = "jti"
        case nonce = "nonce"
        case vc = "vc"
        
    }

    // MARK: - Initializer
    
    public init?(from json: [String: Any]) {

        iss = json[PayloadKeyStrings.iss.rawValue] as? String
        sub = json[PayloadKeyStrings.sub.rawValue] as? String
        aud = json[PayloadKeyStrings.aud.rawValue] as? String
        exp = json[PayloadKeyStrings.exp.rawValue] as? UInt64
        nbf = json[PayloadKeyStrings.nbf.rawValue] as? UInt64
        iat = json[PayloadKeyStrings.iat.rawValue] as? UInt64
        
        cti = json[PayloadKeyStrings.cti.rawValue] as? Data
        
        jti = json[PayloadKeyStrings.jti.rawValue] as? String
        nonce = json[PayloadKeyStrings.nonce.rawValue] as? String
        
        if let vcjson = json[PayloadKeyStrings.vc.rawValue] as? [String: Any] {
            vc = Credential(value: vcjson)
        }

    }
    
    // MARK: - Public Methods
    
    public func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    public func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }

}
