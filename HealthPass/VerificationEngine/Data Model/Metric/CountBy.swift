//
//  CountBy.swift
//  VerificationEngine
//
//  Created by Gautham Velappan on 2/17/22.
//

import Foundation

// MARK: - CountBy
struct CountBy: Codable {
    var scan, scanResult, extract: Bool?
}

// MARK: CountBy convenience initializers and mutators

extension CountBy {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(CountBy.self, from: data)
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
        scan: Bool?? = nil,
        scanResult: Bool?? = nil,
        extract: Bool?? = nil
    ) -> CountBy {
        return CountBy(
            scan: scan ?? self.scan,
            scanResult: scanResult ?? self.scanResult,
            extract: extract ?? self.extract
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
