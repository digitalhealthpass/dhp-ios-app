//
//  Asn1Encoder.swift
//  VerifiableCredential
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
/**
 
 A collection of helper functions for decoding/encoding with Abstract Syntax Notation number One (ASN1) protocol.
 ASN1 is a standard that defines a formalism  for the specification of abstract data types.
 
 */
public class Asn1Encoder {

    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Initializer
    
    public init() {}

    // MARK: - Public Methods
    
    // 32 for ES256
    public func convertRawSignatureIntoAsn1(_ data: Data, _ digestLengthInBytes: Int = 32) -> Data {
        guard data.count >= digestLengthInBytes else {
            return Data()
        }
        let sigR = encodeIntegerToAsn1(data.prefix(data.count - digestLengthInBytes))
        let sigS = encodeIntegerToAsn1(data.suffix(digestLengthInBytes))
        let tagSequence: UInt8 = 0x30
        return Data([tagSequence] + [UInt8(sigR.count + sigS.count)] + sigR + sigS)
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Methods
    
    private func encodeIntegerToAsn1(_ data: Data) -> Data {
        let firstBitIsSet: UInt8 = 0x80 // would be decoded as a negative number
        let tagInteger: UInt8 = 0x02
        if (data.first! >= firstBitIsSet) {
            return Data([tagInteger] + [UInt8(data.count + 1)] + [0x00] + data)
        } else if (data.first! == 0x00) {
            return encodeIntegerToAsn1(data.dropFirst())
        } else {
            return Data([tagInteger] + [UInt8(data.count)] + data)
        }
    }

}
