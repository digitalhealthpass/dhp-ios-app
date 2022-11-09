//
//  CredentialSchema.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

public struct CredentialSchema: Codable {
    enum CodingKeys: String, CodingKey {
        case type, id
    }
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Properties
    
    /**
     id property that MUST be a URI identifying the schema file
     */
    public var id: String?
    
    /**
     type (for example, JsonSchemaValidator2018)
     */
    public var type: String?
    
}

extension CredentialSchema {
  
    public init(value: [String: Any]) {
        id = value["id"] as? String
        type = value["type"] as? String
    }

}
