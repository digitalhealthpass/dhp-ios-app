//
//  Display.swift
//  VerificationEngine
//
//  Created by Gautham Velappan on 8/17/21.
//

//   let displayElement = try Display(json)

import Foundation

// MARK: - Display
public struct Display: Codable {
    public var name: String?
    public var fields: [Field]?
}

// MARK: Display convenience initializers and mutators

extension Display {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Display.self, from: data)
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
        name: String?? = nil,
        fields: [Field]?? = nil
    ) -> Display {
        return Display(
            name: name ?? self.name,
            fields: fields ?? self.fields
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
