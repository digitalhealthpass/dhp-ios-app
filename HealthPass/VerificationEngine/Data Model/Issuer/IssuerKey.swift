//
//  IssuerKey.swift
//  VerificationEngine
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

//   let issuerKey = try IssuerKey(json)

import Foundation

// MARK: - IssuerKey

public struct IssuerKey: Codable {
    public let certificateType, country, kid, rawData: String?
    public let signature, thumbprint: String?
}

// MARK: - IssuerKey convenience initializers and mutators

extension IssuerKey {
    public init(data: Data) throws {
        self = try newJSONDecoder().decode(IssuerKey.self, from: data)
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
        certificateType: String? = nil,
        country: String? = nil,
        kid: String? = nil,
        rawData: String? = nil,
        signature: String? = nil,
        thumbprint: String? = nil
    ) -> IssuerKey {
        return IssuerKey(
            certificateType: certificateType ?? self.certificateType,
            country: country ?? self.country,
            kid: kid ?? self.kid,
            rawData: rawData ?? self.rawData,
            signature: signature ?? self.signature,
            thumbprint: thumbprint ?? self.thumbprint
        )
    }

    public func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    public func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
