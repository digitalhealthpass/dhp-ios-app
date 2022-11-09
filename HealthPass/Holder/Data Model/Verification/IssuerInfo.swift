//
//  DID.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//
import Foundation

struct IssuerInfo: Codable {
    var id: String
    var name: String
    var created: String?
    var updated: String?

    var publicKey: [IssuerPublicKey]
}

struct IssuerPublicKey: Codable {
    var id: String
    var type: String
    var controller: String
    
    var publicKeyJwk: IssuerPublicKeyJwk
}

struct IssuerPublicKeyJwk: Codable {
    var kty: String
    var crv: String
    var x: String
    var y: String
}
