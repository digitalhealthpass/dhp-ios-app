//
//  DataStore+Organization.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

extension DataStore {

    mutating func addNewOrganization(organization: Package) {
        guard let organizationDictionary = organization.rawDictionary else {
            return
        }
        
        guard let allOrganization = allOrganization else {
            allOrganizationDictionary = [organizationDictionary]
            return
        }
        
        guard allOrganization.contains(where: { $0.credential?.id == organization.credential?.id }) else {
            allOrganizationDictionary?.append(organizationDictionary)
            return
        }
        
    }

    func getOrganization(for id: String) -> Package? {
        guard let allOrganization = allOrganization else {
            return nil
        }
        
        return allOrganization.filter { $0.credential?.id == id }.last
    }

    mutating func deleteOrganization(for id: String) {
        guard let allOrganization = allOrganization else { return }
        
        allOrganizationDictionary = allOrganization.filter { $0.credential?.id != id }.compactMap{ $0.rawDictionary }
    }

    mutating func deleteAllOrganizations() {
        currentOrganizationDictionary = nil
        allOrganizationDictionary = nil
    }
}
