//
//  SpecificationConfiguration.swift
//  VerificationEngine
//
//  Created by Gautham Velappan on 2/17/22.
//

import Foundation

// MARK: - SpecificationConfiguration
public struct SpecificationConfiguration: Codable {
    public var id, name, specificationConfigurationDescription, credentialSpec: String?
    public var credentialCategory: String?
    public var credentialSpecDisplayValue, credentialCategoryDisplayValue: String?
    public var classifierRule: Rule?
    public var metrics: [Metric]?
    public var display: [Display]?
    public var rules: [Rule]?
    public var trustLists: [TrustList]?

    enum CodingKeys: String, CodingKey {
        case id, name
        case specificationConfigurationDescription = "description"
        case credentialSpec
        case credentialCategory
        case credentialSpecDisplayValue, credentialCategoryDisplayValue
        case classifierRule
        case metrics, display, rules
        case trustLists
    }
}

// MARK: SpecificationConfiguration convenience initializers and mutators

extension SpecificationConfiguration {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(SpecificationConfiguration.self, from: data)
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
        id: String?? = nil,
        name: String?? = nil,
        specificationConfigurationDescription: String?? = nil,
        credentialSpec: String?? = nil,
        credentialCategory: String?? = nil,
        credentialSpecDisplayValue: String?? = nil,
        credentialCategoryDisplayValue: String?? = nil,
        classifierRule: Rule?? = nil,
        metrics: [Metric]?? = nil,
        display: [Display]?? = nil,
        rules: [Rule]?? = nil,
        trustLists: [TrustList]?? = nil
    ) -> SpecificationConfiguration {
        return SpecificationConfiguration(
            id: id ?? self.id,
            name: name ?? self.name,
            specificationConfigurationDescription: specificationConfigurationDescription ?? self.specificationConfigurationDescription,
            credentialSpec: credentialSpec ?? self.credentialSpec,
            credentialCategory: credentialCategory ?? self.credentialCategory,
            credentialSpecDisplayValue: credentialSpecDisplayValue ?? self.credentialSpecDisplayValue,
            credentialCategoryDisplayValue: credentialCategoryDisplayValue ?? self.credentialCategoryDisplayValue,
            classifierRule: classifierRule ?? self.classifierRule,
            metrics: metrics ?? self.metrics,
            display: display ?? self.display,
            rules: rules ?? self.rules,
            trustLists: trustLists ?? self.trustLists
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

