//
//  Field.swift
//  VerificationEngine
//
//  Created by Gautham Velappan on 8/17/21.
//

//   let field = try Field(json)

import Foundation

// MARK: - Field
public struct Field: Codable {
    public var field: String
    public var displayValue: [String: String]
}

// MARK: Field convenience initializers and mutators

extension Field {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Field.self, from: data)
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
        field: String,
        displayValue: [String: String]
    ) -> Field {
        return Field(
            field: field,
            displayValue: displayValue
        )
    }

    public func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    public func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
