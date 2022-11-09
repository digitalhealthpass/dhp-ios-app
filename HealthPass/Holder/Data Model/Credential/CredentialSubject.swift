//
//  CredentialSubject.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import VerificationEngine

struct CredentialSubject: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case id, gender, ageRange, race, location, issuer
        case consentInfo, basicInfo, technical
    }
    
    var type: String?
    
    ///"type": "id"
    var id: String?
    var gender: String?
    var ageRange: String?
    var race: [String]?
    var location: String?
    
    var issuer: Issuer?
    
    ///"type": "profile"
    var consentInfo: ConsentInfo?
    var basicInfo: BasicInfo?
    
    var technical: Technical?
    
    ///"type": "VerifierCredential"

    /**
     A JSON represenstion of the CredentialSubject object.
     */
    public var rawDictionary: [String: Any]?
    
    /**
     A String represenstion of the CredentialSubject object.
     */
    public var rawString: String?
    
    init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        type = value["type"] as? String
        
        if let type = type, let credentialSubjectType = CredentialSubjectType(rawValue: type) {
            switch credentialSubjectType {
            case .profile:
                updateForProfile(value: value)
            case .id:
                updateForID(value: value)
            }
        }
    }
}

extension CredentialSubject {
    
    mutating private func updateForID(value: [String : Any]) {
        id = value["id"] as? String
        gender = value["gender"] as? String
        ageRange = value["ageRange"] as? String
        race = value["race"] as? [String]
        location = value["location"] as? String
        
        if let issuerData = value["issuer"] as? [String: Any] {
            issuer = Issuer(value: issuerData)
        }
    }
    
    mutating private func updateForProfile(value: [String : Any]) {
        if let consentInfoData = value["consentInfo"] as? [String: Any] {
            consentInfo = ConsentInfo(value: consentInfoData)
        }
        if let basicInfoData = value["basicInfo"] as? [String: Any] {
            basicInfo = BasicInfo(value: basicInfoData)
        }
        if let technicalData = value["technical"] as? [String: Any] {
            technical = Technical(value: technicalData)
        }
    }
    
}

