//
//  VerifierConfiguration.swift
//  VerificationEngine
//
//  Created by Gautham Velappan on 8/16/21.
//

import Foundation

// MARK: - VerifierConfiguration
public struct VerifierConfiguration: Codable {
    public var id, createdBy: String?
    public var createdAt, updatedAt: Date?
    public var version, name, customer, customerID: String?
    public var organization, organizationID, label: String?
    public var offline: Bool?
    public var refresh: Int?
    
    public var verifierType: String?
    public var configuration: JSONAny?
    public var unrestricted: Bool?
    
    public var masterCatalog: Bool?
    public var specificationConfigurations: [SpecificationConfiguration]?
    public var valueSets: [ValueSet]?
    
    public var disabledSpecifications: [SpecificationConfiguration]?
    public var disabledRules: [Rule]?
    
    public var cachedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case version, name, customer
        case customerID = "customerId"
        case organization
        case organizationID = "organizationId"
        case label, offline, refresh, verifierType, configuration, unrestricted
        
        case masterCatalog
        case specificationConfigurations
        case valueSets
        
        case disabledSpecifications
        case disabledRules
        
        case cachedAt = "cached_at"
    }
}

// MARK: VerifierConfiguration convenience initializers and mutators

extension VerifierConfiguration {
    public init(data: Data) throws {
        self = try newJSONDecoder().decode(VerifierConfiguration.self, from: data)
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
        id: String?? = nil,
        createdBy: String?? = nil,
        createdAt: Date?? = nil,
        updatedAt: Date?? = nil,
        version: String?? = nil,
        name: String?? = nil,
        customer: String?? = nil,
        customerID: String?? = nil,
        organization: String?? = nil,
        organizationID: String?? = nil,
        label: String?? = nil,
        offline: Bool?? = nil,
        refresh: Int?? = nil,
        verifierType: String?? = nil,
        configuration: JSONAny?? = nil,
        unrestricted: Bool?? = nil,
        masterCatalog: Bool?? = nil,
        specificationConfigurations: [SpecificationConfiguration]?? = nil,
        valueSets: [ValueSet]?? = nil,
        disabledSpecifications: [SpecificationConfiguration]?? = nil,
        disabledRules: [Rule]?? = nil
    ) -> VerifierConfiguration {
        return VerifierConfiguration(
            id: id ?? self.id,
            createdBy: createdBy ?? self.createdBy,
            createdAt: createdAt ?? self.createdAt,
            updatedAt: updatedAt ?? self.updatedAt,
            version: version ?? self.version,
            name: name ?? self.name,
            customer: customer ?? self.customer,
            customerID: customerID ?? self.customerID,
            organization: organization ?? self.organization,
            organizationID: organizationID ?? self.organizationID,
            label: label ?? self.label,
            offline: offline ?? self.offline,
            refresh: refresh ?? self.refresh,
            verifierType: verifierType ?? self.verifierType,
            configuration: configuration ?? self.configuration,
            unrestricted: unrestricted ?? self.unrestricted,
            masterCatalog: masterCatalog ?? self.masterCatalog,
            specificationConfigurations: specificationConfigurations ?? self.specificationConfigurations,
            valueSets: valueSets ?? self.valueSets,
            disabledSpecifications: disabledSpecifications ?? self.disabledSpecifications,
            disabledRules: disabledRules ?? self.disabledRules
        )
    }
    
    public func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    public func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
