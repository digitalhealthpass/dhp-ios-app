//
//  Rule.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

//   let rule = try Rule(json)

import Foundation

// MARK: - Rule
public struct Rule: Codable {
    public var version, name, predicate, type: String?
    public var category, id: String?
    public var specID: String?
}

// MARK: Rule convenience initializers and mutators

extension Rule {
    public init(data: Data) throws {
        self = try newJSONDecoder().decode(Rule.self, from: data)
    }

    public init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    public init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    public func with(
        version: String?? = nil,
        name: String?? = nil,
        predicate: String?? = nil,
        type: String?? = nil,
        category: String?? = nil,
        id: String?? = nil,
        specID: String?? = nil
    ) -> Rule {
        return Rule(
            version: version ?? self.version,
            name: name ?? self.name,
            predicate: predicate ?? self.predicate,
            type: type ?? self.type,
            category: category ?? self.category,
            id: id ?? self.id,
            specID: specID ?? self.specID
        )
    }

    public func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    public func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

