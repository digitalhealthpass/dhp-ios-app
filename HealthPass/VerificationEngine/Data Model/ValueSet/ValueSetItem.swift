//
//  ValueSetItem.swift
//  VerificationEngine
//
//  Created by Gautham Velappan on 2/17/22.
//

import Foundation

// MARK: - ValueSetItem
struct ValueSetItem: Codable {
    var value: String?
    var itemDescription: String?

    enum CodingKeys: String, CodingKey {
        case value
        case itemDescription = "description"
    }
}

// MARK: ValueSetItem convenience initializers and mutators

extension ValueSetItem {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(ValueSetItem.self, from: data)
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
        value: String?? = nil,
        itemDescription: String?? = nil
    ) -> ValueSetItem {
        return ValueSetItem(
            value: value ?? self.value,
            itemDescription: itemDescription ?? self.itemDescription
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
