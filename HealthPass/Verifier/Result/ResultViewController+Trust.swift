//
//  ResultViewController+Trust.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import PromiseKit
import VerificationEngine

extension ResultViewController {
    
    internal func isTrusted(with specificationConfiguration: SpecificationConfiguration? = nil) -> Promise<SpecificationConfiguration?> {
        self.specificationConfiguration = specificationConfiguration
        
        return Promise { resolver in
            resolver.fulfill(specificationConfiguration)
        }
    }
    
}

