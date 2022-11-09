//
//  ValueSet.swift
//  VerificationEngine
//
//  Created by Gautham Velappan on 2/17/22.
//

import Foundation

public struct ValueSet: Codable {
    var version: String?
    var name, valueSetDescription: String?
    var items: [ValueSetItem]?
    var id: String?
    var source: JSONAny?

    enum CodingKeys: String, CodingKey {
        case version, name
        case valueSetDescription = "description"
        case items, id, source
    }
}

// MARK: ValueSet convenience initializers and mutators

extension ValueSet {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(ValueSet.self, from: data)
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
        version: String?? = nil,
        name: String?? = nil,
        valueSetDescription: String?? = nil,
        items: [ValueSetItem]?? = nil,
        id: String?? = nil,
        source: JSONAny?? = nil
    ) -> ValueSet {
        return ValueSet(
            version: version ?? self.version,
            name: name ?? self.name,
            valueSetDescription: valueSetDescription ?? self.valueSetDescription,
            items: items ?? self.items,
            id: id ?? self.id,
            source: source ?? self.source
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

