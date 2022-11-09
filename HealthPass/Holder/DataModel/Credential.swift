//
//  Credential.swift
//  HealthPass
//
//  Created by Gautham Velappan on 6/25/20.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Credential {
    var context: [String]?
    var type: [String]?
    var id: String?
    var issuer: String?
    var issuanceDate: String?
    var expirationDate: String?
    
    var credentialSchema: [String: String]?
    var credentialSubject: Any?
    
    var proof: Proof?
    
    init(value: [String: Any]) {
        context = value["@context"] as? [String]
        type = value["type"] as? [String]
        id = value["id"] as? String
        issuer = value["issuer"] as? String
        issuanceDate = value["issuanceDate"] as? String
        expirationDate = value["expirationDate"] as? String
        
        credentialSchema = value["credentialSchema"] as? [String: String]
        credentialSubject = value["credentialSubject"] as? String
        
        if let proofData = value["proof"] as? [String: Any] {
            proof = Proof(value: proofData)
        }
    }
}

struct CredentialSubject {
    var credentialSubject: Any?
    
    var label: String?
    var issuerName: String?
    
    var person: Person?
    
    var issueDate: String?
    var loinc: String?
    var result: String?
    
    var status: String?
    var input: Input?
    
    init(value: [String: Any]) {
        label = value["label"] as? String
        issuerName = value["issuerName"] as? String
        
        if let personData = value["person"] as? [String: Any] {
            person = Person(value: personData)
        }
        
        issueDate = value["issueDate"] as? String
        loinc = value["loinc"] as? String
        result = value["result"] as? String
        
        status = value["status"] as? String
        if let inputData = value["input"] as? [String: Any] {
            input = Input(value: inputData)
        }
        
    }
}

struct Person {
    var identifier: String?
    var mrn: String?
    var name: Name?
    
    init(value: [String: Any]) {
        identifier = value["identifier"] as? String
        mrn = value["mrn"] as? String
        
        if let nameData = value["name"] as? [String: Any] {
            name = Name(value: nameData)
        }
    }
}

struct Name {
    var givenName: String?
    var familyName: String?
    
    init(value: [String: Any]) {
        givenName = value["givenName"] as? String
        familyName = value["familyName"] as? String
    }
}

struct Input {
    var covid: String?
    var exposure: String?
    var temperature: String?
    var healthcheck: String?
    
    init(value: [String: Any]) {
        covid = value["covid"] as? String
        exposure = value["exposure"] as? String
        temperature = value["temperature"] as? String
        healthcheck = value["healthcheck"] as? String
    }
}

struct Proof {
    var created: String?
    var creator: String?
    var nonce: String?
    var signatureValue: String?
    var type: String?
    
    init(value: [String: Any]) {
        created = value["created"] as? String
        creator = value["creator"] as? String
        nonce = value["nonce"] as? String
        signatureValue = value["signatureValue"] as? String
        type = value["type"] as? String
    }
}
