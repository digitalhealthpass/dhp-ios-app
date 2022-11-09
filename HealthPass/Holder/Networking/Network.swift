//
//  Network.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Alamofire
import Foundation

public enum EnvTarget: String, CaseIterable {
    case sandbox1
    case sandbox2
    case dev1
    case dev2
    case qa
    case prod

    var canShowRegistration: Bool {
        switch self {
            
        default:
            return true
        }
    }

    var title: String {
        switch self {
        case .sandbox1: return "env.us".localized + " Sandbox 1"
        case .sandbox2: return "env.us".localized + " Sandbox 2"
        case .dev1: return "env.us".localized + " Dev 1"
        case .dev2: return "env.us".localized + " Dev 2"
        case .qa: return "env.us".localized + " QA"
        case .prod: return "env.us".localized

        }
    }
    
    var subTitle: String? {
        switch self {
        case .sandbox1: return "sandbox1.wh-hpass.dev.acme.com"
        case .sandbox2: return "sandbox2.wh-hpass.dev.acme.com"
        case .dev1: return "dev1.wh-hpass.dev.acme.com"
        case .dev2: return "dev2.wh-hpass.dev.acme.com"
        case .qa: return "release1.wh-hpass.dev.acme.com"

        case .prod: return nil
       
        }
    }

    static var debugEnv: [EnvTarget] {
        var items = EnvTarget.allCases
        items.sort { env1, env2 -> Bool in
            env1.title < env2.title
        }
        
        return items
    }
    
    static var releaseEnv: [EnvTarget] {
        return []
    }
}

class Network {
    static var sharedManager: Alamofire.SessionManager = {
        let configuration = URLSessionConfiguration.default
        
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 45
        configuration.timeoutIntervalForResource = 45
        
        configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        
        // Fetch Certificate
        guard let pathToLocalCert = Bundle.main.path(forResource: Network.certificateName, ofType: "cer"),
              let localCertificate = NSData(contentsOfFile: pathToLocalCert) else {
            return Alamofire.SessionManager(configuration: configuration)
        }
        
        guard let secCertificate = SecCertificateCreateWithData(nil, localCertificate) else {
            return Alamofire.SessionManager(configuration: configuration,
                                            serverTrustPolicyManager: ServerTrustPolicyManager(policies: [Network.pinningURL: .disableEvaluation]))
        }
        
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(certificates: [secCertificate], validateCertificateChain: true, validateHost: true)
        
        // Create custom manager
        return Alamofire.SessionManager(configuration: configuration,
                                        serverTrustPolicyManager: ServerTrustPolicyManager(policies: [Network.pinningURL: serverTrustPolicy]))
    }()
    
    static var baseURL: String {
        switch SettingsBundleHelper.shared.savedEnvironment {
        case .sandbox1: return "https://sandbox1.wh-hpass.dev.acme.com/api/v1"
        case .sandbox2: return "https://sandbox2.wh-hpass.dev.acme.com/api/v1"
        case .dev1: return "https://dev1.wh-hpass.dev.acme.com/api/v1"
        case .dev2: return "https://dev2.wh-hpass.dev.acme.com/api/v1"
        case .qa: return "https://release1.wh-hpass.dev.acme.com/api/v1"
        case .prod: return "https://healthpass01.wh-hpass.acme.com/api/v1"
        }
    }
    
    static var issuerId: String {
        switch SettingsBundleHelper.shared.savedEnvironment {
        case .sandbox1: return "hpass.issuer1"
        case .sandbox2: return "hpass.issuer1"
        case .dev1: return "hpass.issuer1"
        case .dev2: return "hpass.issuer1"
        case .qa: return "hpass.issuer1"
        case .prod: return "hpass.issuer1"

        }
    }
    
    static var httpHeaders: [String: String] {
        var httpHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "x-hpass-issuer-id": Network.issuerId,
            "x-hpass-txn-id": NSUUID().uuidString
        ]
        
        if let userAccessToken = DataStore.shared.userAccessToken {
            httpHeaders["Authorization"] = String("Bearer \(userAccessToken)")
        }
        
        return httpHeaders
    }
    
    var httpHeaders: [String: String] {
        return type(of: self).httpHeaders
    }
    
    static var certificateName: String {
        switch SettingsBundleHelper.shared.savedEnvironment {
        case .sandbox1: return "dev"
        case .sandbox2: return "dev"
        case .dev1: return "dev"
        case .dev2: return "dev"
        case .qa: return "dev"
        case .prod: return "release"

        }
    }
    
    static var pinningURL: String {
        switch SettingsBundleHelper.shared.savedEnvironment {
        case .sandbox1: return "sandbox1.wh-hpass.dev.acme.com"
        case .sandbox2: return "sandbox2.wh-hpass.dev.acme.com"
        case .dev1: return "dev1.wh-hpass.dev.acme.com"
        case .dev2: return "dev2.wh-hpass.dev.acme.com"
        case .qa: return "release1.wh-hpass.dev.acme.com"
        case .prod: return "healthpass01.wh-hpass.acme.com"
        }
    }
    
    public static let reachabilityManager = NetworkReachabilityManager()

    static let errors = "errors"
    
    typealias CompletionDictionaryHandler = (Result<[String: Any]>) -> Void
    typealias CompletionDataHandler = (Result<Data>) -> Void
    typealias CompletionHandler = (Result<Any?>) -> Void
    
    static let healthPass = "hpass"
    static let postbox = "postbox"
    static let dataSubmission = "datasubmission"
    static let metering = "metering"

    static let users = "users"
    static let schema = "schemas"
    static let issuers = "issuers"
    static let genericIssuers = "generic-issuers"
    static let credentials = "credentials"
    static let metrics = "metrics"
    static let config = "config"


    static let links = "api/v1/links"
    static let documents = "api/v1/documents"
    static let files = "api/v1/files"
    static let verifierConfigurations = "api/v1/verifier-configurations"

    static let data = "data"
    static let submit = "submit"
    static let onboarding = "onboarding"
    static let organization = "organization"
    static let regconfig = "regconfig"
    static let displayschemaid = "displayschemaid"

    static let mfa = "mfa"
    static let registrationcode = "registration-code"
    static let verificationcode = "verification-code"
    
    static let submitregistration = "submit-registration"

    static let cos = "cos"
    static let owner = "owner"
    static let attachments = "attachments"

    static let consentReceipt = "consentReceipt"
    static let consentRevoke = "consentRevoke"

    static let upload = "upload"
    static let verifier = "verifier"
    static let batch = "batch"
    static let add = "add"
   
    static let content = "content"

    static let publicKeyType = "pkcs1"
}

extension NSError {
    
    static let requestCreateError = NSError(domain: "Client Error", code: 1401,
                                            userInfo: [NSLocalizedDescriptionKey: "networking.clientError".localized])
    
    static let missingDataResponseError = NSError(domain: "Server Error", code: 1402,
                                                  userInfo: [NSLocalizedDescriptionKey: "networking.serverError.data".localized])
    
    static let invalidDataResponseError = NSError(domain: "Server Error", code: 1403,
                                                  userInfo: [NSLocalizedDescriptionKey: "networking.serverError.format".localized])
    
}
