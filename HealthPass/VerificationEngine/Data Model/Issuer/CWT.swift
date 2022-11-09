//
//  CWT.swift
//  VerifiableCredential
//
//  Created by Iryna Horbachova on 01.07.2021.
//

import Foundation
import SwiftCBOR

public struct CWT {
    let iss : String?
    let exp : UInt64?
    let iat : UInt64?
    let nbf : UInt64?
    let sub : Data?
    
    enum PayloadKeys : Int {
        case iss = 1
        case sub = 2
        case exp = 4
        case nbf = 5
        case iat = 6
    }
    
    init?(from cbor: CBOR) {
        guard let decodedPayload = cbor.decodeBytestring()?.asMap() else {
            return nil
        }
        iss = decodedPayload[PayloadKeys.iss]?.asString()
        exp = decodedPayload[PayloadKeys.exp]?.asUInt64() ?? decodedPayload[PayloadKeys.exp]?.asDouble()?.toUInt64()
        iat = decodedPayload[PayloadKeys.iat]?.asUInt64() ?? decodedPayload[PayloadKeys.iat]?.asDouble()?.toUInt64()
        nbf = decodedPayload[PayloadKeys.nbf]?.asUInt64() ?? decodedPayload[PayloadKeys.nbf]?.asDouble()?.toUInt64()
        sub = decodedPayload[PayloadKeys.sub]?.asData()
    }
}
