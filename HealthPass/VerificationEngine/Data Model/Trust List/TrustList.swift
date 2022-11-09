//
//  TrustList.swift
//  VerificationEngine
//
//  Created by Gautham Velappan on 8/17/21.
//

//   let trustList = try TrustList(json)

import Foundation

// MARK: - TrustList
public struct TrustList: Codable {
    var version, name: String?
    var items: [TrustListItem]?
    var type, id: String?
}

// MARK: TrustList convenience initializers and mutators

extension TrustList {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(TrustList.self, from: data)
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
        items: [TrustListItem]?? = nil,
        type: String?? = nil,
        id: String?? = nil
    ) -> TrustList {
        return TrustList(
            version: version ?? self.version,
            name: name ?? self.name,
            items: items ?? self.items,
            type: type ?? self.type,
            id: id ?? self.id
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

