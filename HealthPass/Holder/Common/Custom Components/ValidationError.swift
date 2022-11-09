//
//  ValidationError.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

extension NSError {
    /// Error method which would create NSError object for a given error dictonary and status code
    ///
    /// - parameter errorObject: Dictionarfy object which would accept the localized error messages
    ///
    /// - parameter statusCode: Int object which would accept error code
    ///
    /// - returns: A NSError Object.
    ///
    public func getError(for errorObject: [String: Any], with statusCode: Int? = 1400) -> NSError {
        let domain = (errorObject["errorcode"] as? String) ?? "server-error"
        return NSError(domain: domain, code: statusCode ?? 1400, userInfo: errorObject)
    }
    
    /// Error method which would return a localized error message for the current error
    ///
    /// - returns: A String Tuple Object which has error title and error message.
    ///
    // swiftlint:disable:next cyclomatic_complexity
    public func getGenericErrorContent() -> (String?, String?) {
        let statusCode = code
        
        var errorTitle: String?
        var errorMessage: String?
        
        switch statusCode {
        case 4: // Error code 4 is typically the server error 503 where the ALamofire not able to parse the string content of the error message
            errorTitle = "error.server.title".localized
            errorMessage = "error.server.4.message".localized
            
        case 53: // Error code 53 is typically when the app was backgrounded and resumed when the API call was made
            errorTitle = "error.client.title".localized
            errorMessage = "error.client.53.message".localized
            
        case 200: // Error code 200 is typically Success but API warning
            if let level = userInfo["level"] as? String {
                errorTitle = NSLocalizedString(level, comment: "")
            } else {
                errorTitle = userInfo["level"] as? String
            }
            
            if let message = userInfo["message"] as? String {
                errorMessage = NSLocalizedString(message, comment: "")
            } else {
                errorMessage = userInfo["message"] as? String
            }
                        
        case 1401:
            errorTitle = "error.client.title".localized
            errorMessage = "error.client.1401.message".localized
            
        case 1402:
            errorTitle = "error.server.title".localized
            errorMessage = "error.server.1402.message".localized
            
        case 1403:
            errorTitle = "error.server.title".localized
            errorMessage = "error.server.1403.message".localized
            
        case -1021 ... -998:
            errorTitle = "error.network.title".localized
            errorMessage = "error.network.message".localized
            
        case 400 ... 499:
            errorTitle = "error.client.title".localized
            errorMessage = "error.client.400s.message".localized
            
        case 500 ... 599:
            errorTitle = "error.server.title".localized
            errorMessage = "error.server.500s.message".localized
            
        default: // other errors to show user friendly message untill we get the error list
            errorTitle = "error.default.title".localized
            errorMessage = "error.default.message".localized
        }
        
        return (errorTitle, errorMessage)
    }
}
