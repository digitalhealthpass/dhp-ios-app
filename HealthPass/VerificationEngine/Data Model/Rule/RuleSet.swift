//
//  RuleSet.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

//   let ruleSet = try RuleSet(json)

import Foundation

// MARK: - RuleSet
struct RuleSet: Codable {
    var id, version, name, type: String?
    var category: String?
    var rules: [Rule]?
    var predicate: String?
}

// MARK: RuleSet convenience initializers and mutators

extension RuleSet {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(RuleSet.self, from: data)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        id: String?? = nil,
        version: String?? = nil,
        name: String?? = nil,
        type: String?? = nil,
        category: String?? = nil,
        rules: [Rule]?? = nil,
        predicate: String?? = nil
    ) -> RuleSet {
        return RuleSet(
            id: id ?? self.id,
            version: version ?? self.version,
            name: name ?? self.name,
            type: type ?? self.type,
            category: category ?? self.category,
            rules: rules ?? self.rules,
            predicate: predicate ?? self.predicate
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
