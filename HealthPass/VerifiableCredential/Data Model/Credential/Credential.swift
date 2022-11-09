//
//  Credential.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit
import FHIR

public struct Credential: Codable {
    enum CodingKeys: String, CodingKey {
        case context = "@context"
        //case type, id, issuer, issuanceDate, expirationDate, credentialSchema, credentialSubject, proof, obfuscation
    }
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Properties
    
    /**
     The value of the @context property MUST be an ordered set where the first item is a URI with the value https://www.w3.org/2018/credentials/v1. For reference, a copy of the base context is provided in Appendix § B. Base Context. Subsequent items in the array MUST express context information and be composed of any combination of URIs or objects. It is RECOMMENDED that each URI in the @context be one which, if dereferenced, results in a document containing machine-readable information about the @context.
     */
    public var context: [String]?
    
    
    /**
     The value of the type property MUST be, or map to (through interpretation of the @context property), one or more URIs. If more than one URI is provided, the URIs MUST be interpreted as an unordered set. Syntactic conveniences SHOULD be used to ease developer usage. Such conveniences might include JSON-LD terms. It is RECOMMENDED that each URI in the type be one which, if dereferenced, results in a document containing machine-readable information about the type.
     */
    public var type: [String]?
    
    /**
     The value of the id property MUST be a single URI. It is RECOMMENDED that the URI in the id be one which, if dereferenced, results in a document containing machine-readable information about the id.
     */
    public var id: String?
    
    /**
     The value of the issuer property MUST be either a URI or an object containing an id property. It is RECOMMENDED that the URI in the issuer or its id be one which, if dereferenced, results in a document containing machine-readable information about the issuer that can be used to verify the information expressed in the credential.
     */
    public var issuer: String?
    
    /**
     A credential MUST have an issuanceDate property. The value of the issuanceDate property MUST be a string value of an [RFC3339] combined date and time string representing the date and time the credential becomes valid, which could be a date and time in the future. Note that this value represents the earliest point in time at which the information associated with the credentialSubject property becomes valid.
     */
    public var issuanceDate: String?
    
    public var nonTransferable: Bool?
    /**
     If present, the value of the expirationDate property MUST be a string value of an [RFC3339] combined date and time string representing the date and time the credential ceases to be valid.
     */
    public var expirationDate: String?
    
    /**
     The value of the credentialSchema property MUST be one or more data schemas that provide verifiers with enough information to determine if the provided data conforms to the provided schema. Each credentialSchema MUST specify its type (for example, JsonSchemaValidator2018), and an id property that MUST be a URI identifying the schema file. The precise contents of each data schema is determined by the specific type definition.
     */
    public var credentialSchema: CredentialSchema?
    
    
    /**
     The value of the credentialSubject property is defined as a set of objects that contain one or more properties that are each related to a subject of the verifiable credential. Each object MAY contain an id, as described in Section § 4.2 Identifiers.
     */
    public var credentialSubject: [String : Any]?
    
    
    /**
     One or more cryptographic proofs that can be used to detect tampering and verify the authorship of a credential or presentation. The specific method used for an embedded proof MUST be included using the type property.
     */
    public var proof: Proof?
    
    public var obfuscation: [Obfuscation]?
    
    public var evidence: [Evidence]?
    /**
     A JSON represenstion of the Credential object. Key-Value pairs which contain all the high-level credential details
     */
    public var rawDictionary: [String: Any]?
    
    /**
     A String represenstion of the Credential object.
     */
    public var rawString: String?
    
    // MARK: - Initializers
    
    public init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        context = value["@context"] as? [String]
        
        type = value["type"] as? [String]
        id = value["id"] as? String
        issuer = value["issuer"] as? String
        issuanceDate = value["issuanceDate"] as? String
        expirationDate = value["expirationDate"] as? String
        nonTransferable = value["nonTransferable"] as? Bool
        
        if let credentialSchemaDictionary = value["credentialSchema"],
           let credentialSchemaData = try? JSONSerialization.data(withJSONObject: credentialSchemaDictionary, options: JSONSerialization.WritingOptions()) as Data {
            credentialSchema = try? JSONDecoder().decode(CredentialSchema.self, from: credentialSchemaData)
        }
        
        credentialSubject = value["credentialSubject"] as? [String : Any]
        
        if let proofDictionary = value["proof"],
           let proofData = try? JSONSerialization.data(withJSONObject: proofDictionary, options: JSONSerialization.WritingOptions()) as Data {
            proof = try? JSONDecoder().decode(Proof.self, from: proofData)
        }
        
        if let obfuscatedFieldsDictionaryArray = value["obfuscation"] as? [[String: Any]] {
            let obfuscatedFieldsDataArray = obfuscatedFieldsDictionaryArray.compactMap {
                try? JSONSerialization.data(withJSONObject: $0, options: JSONSerialization.WritingOptions()) as Data
            }
            
            obfuscation = obfuscatedFieldsDataArray.compactMap {
                try? JSONDecoder().decode(Obfuscation.self, from: $0)
            }
        }
        
        if let evidenceDictionaryArray = value["evidence"] as? [[String: Any]] {
            let evidenceFieldsDataArray = evidenceDictionaryArray.compactMap {
                try? JSONSerialization.data(withJSONObject: $0, options: JSONSerialization.WritingOptions()) as Data
            }
            
            evidence = evidenceFieldsDataArray.compactMap {
                try? JSONDecoder().decode(Evidence.self, from: $0)
            }
        }
    }
    
    public init(value: String) {
        rawString = value
        rawDictionary = jsonObject(from: value)
        
        context = rawDictionary?["@context"] as? [String]
        
        type = rawDictionary?["type"] as? [String]
        id = rawDictionary?["id"] as? String
        issuer = rawDictionary?["issuer"] as? String
        issuanceDate = rawDictionary?["issuanceDate"] as? String
        expirationDate = rawDictionary?["expirationDate"] as? String
        nonTransferable = rawDictionary?["nonTransferable"] as? Bool
        
        credentialSubject = rawDictionary?["credentialSubject"] as? [String: Any]
        
        if let credentialSchemaDictionary = rawDictionary?["credentialSchema"],
           let credentialSchemaData = try? JSONSerialization.data(withJSONObject: credentialSchemaDictionary, options: JSONSerialization.WritingOptions()) as Data {
            credentialSchema = try? JSONDecoder().decode(CredentialSchema.self, from: credentialSchemaData)
        }
        
        if let proofDictionary = rawDictionary?["proof"],
           let proofData = try? JSONSerialization.data(withJSONObject: proofDictionary, options: JSONSerialization.WritingOptions()) as Data {
            proof = try? JSONDecoder().decode(Proof.self, from: proofData)
        }
        
        if let obfuscatedFieldsDictionaryArray = rawDictionary?["obfuscation"] as? [[String: Any]] {
            let obfuscatedFieldsDataArray = obfuscatedFieldsDictionaryArray.compactMap {
                try? JSONSerialization.data(withJSONObject: $0, options: JSONSerialization.WritingOptions()) as Data
            }
            
            obfuscation = obfuscatedFieldsDataArray.compactMap {
                try? JSONDecoder().decode(Obfuscation.self, from: $0)
            }
        }
        
        if let evidenceDictionaryArray = rawDictionary?["evidence"] as? [[String: Any]] {
            let evidenceFieldsDataArray = evidenceDictionaryArray.compactMap {
                try? JSONSerialization.data(withJSONObject: $0, options: JSONSerialization.WritingOptions()) as Data
            }
            
            evidence = evidenceFieldsDataArray.compactMap {
                try? JSONDecoder().decode(Evidence.self, from: $0)
            }
        }
    }
    
    private func jsonObject(from stringValue: String) -> [String : Any]? {
        // 1st - try decoding from a string that contains the json data
        // 2nd - try decoding from a base 64 encoded string containing the json data
        if let jsonObject = try? JSONSerialization.jsonObject(with:Data(stringValue.utf8), options: []) as? [String: Any] {
            return jsonObject
        } else if let data = Data(base64Encoded: stringValue, options: .ignoreUnknownCharacters), let jsonObject = try? JSONSerialization.jsonObject(with:data, options: []) as? [String: Any] {
            return jsonObject
        }
        return nil
    }
    
}

public extension Credential {
    
    var isFHIRCredential: Bool {
        if credentialSubject?["fhirBundle"] != nil {
            return true
        }
        
        if let type = type, type.contains("FHIR") {
            return true
        }
        
        return false
    }
    
    var fhirBundle: FHIR.Bundle? {
        guard let fhirBundleJSON = credentialSubject?["fhirBundle"] as? FHIRJSON else {
            return nil
        }
        
        return try? FHIR.Bundle(json: fhirBundleJSON)
    }
    
    var fhirResources: [FHIR.Resource]? {
        guard let fhirBundle = fhirBundle else {
            return nil
        }
        
        guard let entry = fhirBundle.entry else {
            return nil
        }
        
        return entry.compactMap({ $0.resource })
    }
    
}
