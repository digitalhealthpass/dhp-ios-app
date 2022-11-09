//
//  Item.swift
//  VerificationEngine
//
//  Created by Gautham Velappan on 8/17/21.
//
//   let item = try Item(json)

import Foundation

// MARK: - Item
struct TrustListItem: Codable {
    var purpose, publisher: String?
    var schemas, issuers: [JSONAny]?
}

// MARK: Item convenience initializers and mutators

extension TrustListItem {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(TrustListItem.self, from: data)
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
        purpose: String?? = nil,
        publisher: String?? = nil,
        schemas: [JSONAny]?? = nil,
        issuers: [JSONAny]?? = nil
    ) -> TrustListItem {
        return TrustListItem(
            purpose: purpose ?? self.purpose,
            publisher: publisher ?? self.publisher,
            schemas: schemas ?? self.schemas,
            issuers: issuers ?? self.issuers
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
