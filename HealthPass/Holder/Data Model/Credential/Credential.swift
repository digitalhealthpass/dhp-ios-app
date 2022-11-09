//
//  Credential.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import VerifiableCredential

struct Credential: Codable {
    enum CodingKeys: String, CodingKey {
        case context = "@context"
        //case type, id, issuer, issuanceDate, expirationDate, credentialSchema, credentialSubject, proof, obfuscation
    }
    
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
    public var credentialSubject: CredentialSubject?

    
    /**
     One or more cryptographic proofs that can be used to detect tampering and verify the authorship of a credential or presentation. The specific method used for an embedded proof MUST be included using the type property.
     */
    public var proof: Proof?
    
    public var obfuscation: [Obfuscation]?
    
    /**
     A JSON represenstion of the Credential object. Key-Value pairs which contain all the high-level credential details
     */
    public var rawDictionary: [String: Any]?
    
    /**
     A String represenstion of the Credential object.
     */
    public var rawString: String?
    
    init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        context = rawDictionary?["@context"] as? [String]

        type = value["type"] as? [String]
        id = value["id"] as? String
        issuer = value["issuer"] as? String
        issuanceDate = value["issuanceDate"] as? String
        expirationDate = value["expirationDate"] as? String
        
        if let credentialSchemaData = value["credentialSchema"] as? [String: Any] {
            credentialSchema = CredentialSchema(value: credentialSchemaData)
        }
        
        if let credentialSubjectData = value["credentialSubject"] as? [String: Any] {
            credentialSubject = CredentialSubject(value: credentialSubjectData)
        }
        
        if let proofData = value["proof"] as? [String: Any] {
            proof = Proof(value: proofData)
        }
        
        if let obfuscatedFields = value["obfuscation"] as? [[String: Any]] {
            obfuscation = obfuscatedFields.compactMap { Obfuscation(value: $0) }
        }
    }
    
    init(value: String) {
        rawString = value
        rawDictionary = (try? JSONSerialization.jsonObject(with:Data(value.utf8), options: []) as? [String : Any]) ?? [String : Any]()
        
        context = rawDictionary?["@context"] as? [String]

        type = rawDictionary?["type"] as? [String]
        id = rawDictionary?["id"] as? String
        issuer = rawDictionary?["issuer"] as? String
        issuanceDate = rawDictionary?["issuanceDate"] as? String
        expirationDate = rawDictionary?["expirationDate"] as? String
        
        if let credentialSchemaData = rawDictionary?["credentialSchema"] as? [String: Any] {
            credentialSchema = CredentialSchema(value: credentialSchemaData)
        }
        
        if let credentialSubjectData = rawDictionary?["credentialSubject"] as? [String: Any] {
            credentialSubject = CredentialSubject(value: credentialSubjectData)
        }
        
        if let proofData = rawDictionary?["proof"] as? [String: Any] {
            proof = Proof(value: proofData)
        }
        
        if let obfuscatedFields = rawDictionary?["obfuscation"] as? [[String: Any]] {
            obfuscation = obfuscatedFields.compactMap { Obfuscation(value: $0) }
        }
    }
    
}
