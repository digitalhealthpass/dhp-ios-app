//
//  Metric.swift
//  VerificationEngine
//
//  Created by Gautham Velappan on 2/17/22.
//

import Foundation

// MARK: - Metric
public struct Metric: Codable {
    var name: String?
    public var extract: JSONAny?
    var countBy: CountBy?
}

// MARK: Metric convenience initializers and mutators

extension Metric {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Metric.self, from: data)
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
        extract: JSONAny?? = nil,
        countBy: CountBy?? = nil
    ) -> Metric {
        return Metric(
            name: name ?? self.name,
            extract: extract ?? self.extract,
            countBy: countBy ?? self.countBy
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
