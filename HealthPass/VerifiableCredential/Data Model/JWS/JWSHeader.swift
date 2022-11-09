//
//  JWSHeader.swift
//  VerifiableCredential
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

public enum SignatureAlgorithm: String, Codable {
    case es256 = "ES256"
}

public enum CompressionAlgorithm: String, Codable {
    
    /// DEFLATE, also known as ZLIB.
    /// For more information, see https://tools.ietf.org/html/rfc1951.
    case deflate = "DEF"
}

public struct JWSHeader: Codable {
    
    /// Cryptographic algorithm used to secure the JWS
    public let alg: SignatureAlgorithm
    /// Hint indicating which key was used to secure the JWS
    public let kid: String
    /// Media type of the complete JWS
    public let typ: String?
    /// Compression Algorithm
    public let zip: CompressionAlgorithm
    
}
