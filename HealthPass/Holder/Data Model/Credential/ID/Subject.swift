//
//  Subject.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

struct Subject: Codable {
    enum CodingKeys: String, CodingKey {
        case id, gender, ageRange, race, location
        case birthdate, key, name, nationality, passport
    }
    
    var id: String?
    var gender: String?
    var ageRange: String?
    var race: String?
    var location: String?

    var birthdate: String?
    var key: String?
    var name: Name?
    var nationality: String?
    var passport: String?

    /**
     A JSON represenstion of the Input object.
     */
    public var rawDictionary: [String: Any]?
    
    /**
     A String represenstion of the Input object.
     */
    public var rawString: String?
    
    init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        id = value["id"] as? String
        gender = value["gender"] as? String
        ageRange = value["ageRange"] as? String
        race = value["race"] as? String
        location = value["location"] as? String
        
        birthdate = value["birthdate"] as? String
        key = value["key"] as? String
        if let nameData = value["name"] as? [String: Any] {
            name = Name(value: nameData)
        }
        nationality = value["nationality"] as? String
        passport = value["passport"] as? String
    }
}

