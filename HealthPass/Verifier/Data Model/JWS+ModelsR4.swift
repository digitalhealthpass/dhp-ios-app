//
//  JWS+ModelsR4.swift
//  Verifier
//
//  Created by John Martino on 2021-06-21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import VerifiableCredential
import ModelsR4

extension JWS {
    var fhir: ResourceProxy? {
        guard let payloadData = self.payloadData else {
            return nil
        }

        guard let payloadJSON = try? JSONSerialization.jsonObject(with: payloadData) as? [String : Any] else {
            return nil
        }

        guard let vcJSON = payloadJSON["vc"] as? [String : Any],
              let credentialSubjectJSON = vcJSON["credentialSubject"] as? [String : Any],
              let fhirBundleJSON = credentialSubjectJSON["fhirBundle"] as? [String : Any] else {
            return nil
        }

        guard let fhirBundleData = try? JSONSerialization.data(withJSONObject: fhirBundleJSON, options: [.withoutEscapingSlashes, .prettyPrinted]) as Data else {
            return nil
        }

        let decoder = JSONDecoder()
        guard let proxy = try? decoder.decode(ResourceProxy.self, from: fhirBundleData) else {
            return nil
        }

        return proxy
    }
}
