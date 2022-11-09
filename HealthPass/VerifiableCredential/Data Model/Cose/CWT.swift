//
//  CWT.swift
//  VerifiableCredential
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import SwiftCBOR

/**
 
 CBOR Web Token (CWT) is a compact means of representing claims to be transferred between two parties.
 
 */
public struct CWT {
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Properties
    
    /// Issuer of the token
    public let iss : String?
    /// Expiration time after which token must not be accepted for processing
    public let exp : UInt64?
    /// Time at which the token was issued
    public let iat : UInt64?
    /// Time before which the token must not be accepted for processing
    public let nbf : UInt64?
    /// Principal that is the subject of the token
    public let sub : Data?
    /// Health Certificate claim
    public let euHealthCert : EuHealthCert?

    public enum PayloadKeys : Int {
        case iss = 1
        case sub = 2
        case exp = 4
        case nbf = 5
        case iat = 6
        case hcert = -260
        
        enum HcertKeys : Int {
            case euHealthCertV1 = 1
        }
    }

    // MARK: - Initializer
    
    public init?(from cbor: CBOR) {
        guard let decodedPayload = cbor.decodeBytestring()?.asMap() else {
           return nil
        }
        
        iss = decodedPayload[PayloadKeys.iss]?.asString()
        exp = decodedPayload[PayloadKeys.exp]?.asUInt64()
        iat = decodedPayload[PayloadKeys.iat]?.asUInt64()
        nbf = decodedPayload[PayloadKeys.nbf]?.asUInt64()
        sub = decodedPayload[PayloadKeys.sub]?.asData()
        
        var euHealthCert : EuHealthCert? = nil
        if let hCertMap = decodedPayload[PayloadKeys.hcert]?.asMap(),
           let certData = hCertMap[PayloadKeys.HcertKeys.euHealthCertV1]?.asData() {
           euHealthCert = try? CodableCBORDecoder().decode(EuHealthCert.self, from: certData)
        }
        self.euHealthCert = euHealthCert
    }
    
}

// MARK: - CertType

public enum CertType : String, Codable {
    case test = "t"
    case recovery = "r"
    case vaccination = "v"
    
    public var displayValue: String {
        switch self {
        case .test: return "Test"
        case .recovery: return "Recovery"
        case .vaccination: return "Vaccination"
        }
    }
}

// MARK: - EuHealthCert

public struct EuHealthCert : Codable {
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Properties
    
    public let person: Person
    public let dateOfBirth : String
    public let version: String
    public let vaccinations: [Vaccination]?
    public let recovery: [Recovery]?
    public let tests: [Test]?
    
    public var type : CertType {
        get {
            switch self {
            case _ where nil != vaccinations && vaccinations?.count ?? 0 > 0:
                return .vaccination
            case _ where nil != recovery && recovery?.count ?? 0 > 0:
                return .recovery
            default:
                return .test
            }
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    private enum CodingKeys : String, CodingKey {
        case person = "nam"
        case dateOfBirth = "dob"
        case vaccinations = "v"
        case recovery = "r"
        case tests = "t"
        case version = "ver"
    }
    
    // MARK: - Initializer
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.person = try container.decode(Person.self, forKey: .person)
        self.version = try container.decode(String.self, forKey: .version)
        self.dateOfBirth = try container.decode(String.self, forKey: .dateOfBirth)
        self.vaccinations = try? container.decode([Vaccination].self, forKey: .vaccinations)
        self.tests = try? container.decode([Test].self, forKey: .tests)
        self.recovery = try? container.decode([Recovery].self, forKey: .recovery)
        
        if (vaccinations.moreThanOne && (recovery.moreThanOne || tests.moreThanOne)) ||
            tests.moreThanOne && (recovery.moreThanOne || vaccinations.moreThanOne) ||
            recovery.moreThanOne && (tests.moreThanOne || vaccinations.moreThanOne) {
            throw ValidationError.CBOR_DESERIALIZATION_FAILED
        }
        
        if (version.isMinimalVersion(major: 1, minor: 3) && !(vaccinations.exactlyOne || recovery.exactlyOne || tests.exactlyOne)) {
            throw ValidationError.CBOR_DESERIALIZATION_FAILED
        }
    }
}

// MARK: - Person

public struct Person : Codable {
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Properties
    
    public let givenName: String?
    public let standardizedGivenName: String?
    public let familyName: String?
    public let standardizedFamilyName: String
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    private enum CodingKeys : String, CodingKey {
        case givenName = "gn"
        case standardizedGivenName = "gnt"
        case familyName = "fn"
        case standardizedFamilyName = "fnt"
    }
    
    // MARK: - Initializer
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.givenName = try? container.decode(String.self, forKey: .givenName)
        self.standardizedGivenName = try? container.decode(String.self, forKey: .standardizedGivenName)
        self.familyName = try? container.decode(String.self, forKey: .familyName)
        self.standardizedFamilyName = try container.decode(String.self, forKey: .standardizedFamilyName)
    }
}

public struct Vaccination : Codable {
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Properties
    
    public let disease: String
    public let vaccine: String
    public let medicinialProduct: String
    public let marketingAuthorizationHolder: String
    public let doseNumber: UInt64
    public let totalDoses: UInt64
    public let vaccinationDate: String
    public let country: String
    public let certificateIssuer: String
    public let certificateIdentifier: String
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    private enum CodingKeys : String, CodingKey {
        case disease = "tg"
        case vaccine = "vp"
        case medicinialProduct = "mp"
        case marketingAuthorizationHolder = "ma"
        case doseNumber = "dn"
        case totalDoses = "sd"
        case vaccinationDate = "dt"
        case country = "co"
        case certificateIssuer = "is"
        case certificateIdentifier = "ci"
    }
    
    // MARK: - Initializer
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.disease = try container.decode(String.self, forKey: .disease).trimmingCharacters(in: .whitespacesAndNewlines)
        self.vaccine = try container.decode(String.self, forKey: .vaccine).trimmingCharacters(in: .whitespacesAndNewlines)
        self.medicinialProduct = try container.decode(String.self, forKey: .medicinialProduct).trimmingCharacters(in: .whitespacesAndNewlines)
        self.marketingAuthorizationHolder = try container.decode(String.self, forKey: .marketingAuthorizationHolder).trimmingCharacters(in: .whitespacesAndNewlines)
        self.doseNumber = try container.decode(UInt64.self, forKey: .doseNumber)
        guard 1..<10 ~= doseNumber else {
            throw ValidationError.CBOR_DESERIALIZATION_FAILED
        }
        self.totalDoses = try container.decode(UInt64.self, forKey: .totalDoses)
        guard 1..<10 ~= totalDoses else {
            throw ValidationError.CBOR_DESERIALIZATION_FAILED
        }
        self.vaccinationDate = try container.decode(String.self, forKey: .vaccinationDate)
        guard vaccinationDate.isValidIso8601Date() else {
            throw ValidationError.CBOR_DESERIALIZATION_FAILED
        }
        self.country = try container.decode(String.self, forKey: .country).trimmingCharacters(in: .whitespacesAndNewlines)
        self.certificateIssuer = try container.decode(String.self, forKey: .certificateIssuer)
        self.certificateIdentifier = try container.decode(String.self, forKey: .certificateIdentifier)
    }
}

// MARK: - Test

public struct Test : Codable {
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Properties
    
    public let disease: String
    public let type: String
    public let testName: String?
    public let manufacturer: String?
    public let timestampSample: String
    public let timestampResult : String?
    public let result: String
    public let testCenter: String
    public let country: String
    public let certificateIssuer: String
    public let certificateIdentifier: String
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    private enum CodingKeys : String, CodingKey {
        case disease = "tg"
        case type = "tt"
        case testName = "nm"
        case manufacturer = "ma"
        case timestampSample = "sc"
        case timestampResult = "dr"
        case result = "tr"
        case testCenter = "tc"
        case country = "co"
        case certificateIssuer = "is"
        case certificateIdentifier = "ci"
    }
    
    // MARK: - Initializer
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.disease = try container.decode(String.self, forKey: .disease).trimmingCharacters(in: .whitespacesAndNewlines)
        self.type = try container.decode(String.self, forKey: .type).trimmingCharacters(in: .whitespacesAndNewlines)
        self.testName = try? container.decode(String.self, forKey: .testName)
        self.manufacturer = try? container.decode(String.self, forKey: .manufacturer).trimmingCharacters(in: .whitespacesAndNewlines)
        self.timestampSample = try container.decode(String.self, forKey: .timestampSample)
        guard timestampSample.isValidIso8601DateTime() else {
            throw ValidationError.CBOR_DESERIALIZATION_FAILED
        }
        self.timestampResult = try? container.decode(String.self, forKey: .timestampResult)
        if let timestampResult = timestampResult, !timestampResult.isValidIso8601DateTime() {
            throw ValidationError.CBOR_DESERIALIZATION_FAILED
        }
        self.result = try container.decode(String.self, forKey: .result).trimmingCharacters(in: .whitespacesAndNewlines)
        self.testCenter = try container.decode(String.self, forKey: .testCenter)
        self.country = try container.decode(String.self, forKey: .country).trimmingCharacters(in: .whitespacesAndNewlines)
        self.certificateIssuer = try container.decode(String.self, forKey: .certificateIssuer)
        self.certificateIdentifier = try container.decode(String.self, forKey: .certificateIdentifier)
    }
    
}

// MARK: - Recovery

public struct Recovery : Codable {
    
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Properties
    
    public let disease: String
    public let dateFirstPositiveTest: String
    public let countryOfTest: String
    public let certificateIssuer: String
    public let validFrom: String
    public let validUntil: String
    public let certificateIdentifier: String
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    private enum CodingKeys : String, CodingKey {
        case disease = "tg"
        case dateFirstPositiveTest = "fr"
        case countryOfTest = "co"
        case certificateIssuer = "is"
        case validFrom = "df"
        case validUntil = "du"
        case certificateIdentifier = "ci"
    }
    
    // MARK: - Initializer
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.disease = try container.decode(String.self, forKey: .disease).trimmingCharacters(in: .whitespacesAndNewlines)
        let dateFirstPositiveTest = try container.decode(String.self, forKey: .dateFirstPositiveTest)
        guard dateFirstPositiveTest.isValidIso8601Date() else {
            throw ValidationError.CBOR_DESERIALIZATION_FAILED
        }
        self.dateFirstPositiveTest = dateFirstPositiveTest
        self.countryOfTest = try container.decode(String.self, forKey: .countryOfTest).trimmingCharacters(in: .whitespacesAndNewlines)
        self.validFrom = try container.decode(String.self, forKey: .validFrom)
        guard validFrom.isValidIso8601Date() else {
            throw ValidationError.CBOR_DESERIALIZATION_FAILED
        }
        self.validUntil = try container.decode(String.self, forKey: .validUntil)
        guard validUntil.isValidIso8601Date() else {
            throw ValidationError.CBOR_DESERIALIZATION_FAILED
        }
        self.certificateIssuer = try container.decode(String.self, forKey: .certificateIssuer)
        self.certificateIdentifier = try container.decode(String.self, forKey: .certificateIdentifier)
    }
}

// MARK: - String validation extensions

extension String {
    func isValidIso8601Date() -> Bool {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withFullDate
        return formatter.date(from: self) != nil
    }
    
    func isValidIso8601DateTime() -> Bool {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = .withFractionalSeconds
        return fractionalFormatter.date(from: self) != nil || ISO8601DateFormatter().date(from: self) != nil
    }
    
    func conformsTo(regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }
    
    func isMinimalVersion(major: Int, minor: Int) -> Bool {
        let version = self.split(separator: ".")
        guard version.count > 2,
              let majorVersion = Int(version[0]),
              let minorVersion = Int(version[1]) else {
            return false
        }
        return majorVersion >= major && minorVersion >= minor
    }
}

// MARK: - Optional Extension

extension Optional where Wrapped : Collection {
    var moreThanOne : Bool {
        guard let this = self else {
            return false
        }
        return this.count >= 1
    }
    
    var exactlyOne : Bool {
        guard let this = self else {
            return false
        }
        return this.count == 1
    }
}

/// Enum describing COSE/CBOR Validation errors
public enum ValidationError : String, Error, Codable {
    case GENERAL_ERROR = "GENERAL_ERROR"
    case INVALID_SCHEME_PREFIX = "INVALID_SCHEME_PREFIX"
    case DECOMPRESSION_FAILED = "DECOMPRESSION_FAILED"
    case BASE_45_DECODING_FAILED = "BASE_45_DECODING_FAILED"
    case COSE_DESERIALIZATION_FAILED = "COSE_DESERIALIZATION_FAILED"
    case CBOR_DESERIALIZATION_FAILED = "CBOR_DESERIALIZATION_FAILED"
    case CWT_EXPIRED = "CWT_EXPIRED"
    case QR_CODE_ERROR = "QR_CODE_ERROR"
    case CERTIFICATE_QUERY_FAILED = "CERTIFICATE_QUERY_FAILED"
    case USER_CANCELLED = "USER_CANCELLED"
    case TRUST_SERVICE_ERROR = "TRUST_SERVICE_ERROR"
    case KEY_NOT_IN_TRUST_LIST = "KEY_NOT_IN_TRUST_LIST"
    case PUBLIC_KEY_EXPIRED = "PUBLIC_KEY_EXPIRED"
    case UNSUITABLE_PUBLIC_KEY_TYPE = "UNSUITABLE_PUBLIC_KEY_TYPE"
    case KEY_CREATION_ERROR = "KEY_CREATION_ERROR"
    case KEYSTORE_ERROR = "KEYSTORE_ERROR"
    case SIGNATURE_INVALID = "SIGNATURE_INVALID"
    

    public var message : String {
        switch self {
        case .GENERAL_ERROR: return "General error"
        case .INVALID_SCHEME_PREFIX: return "Invalid scheme prefix"
        case .DECOMPRESSION_FAILED: return "ZLib decompression failed"
        case .BASE_45_DECODING_FAILED: return "Base45 decoding failed"
        case .COSE_DESERIALIZATION_FAILED: return "COSE deserialization failed"
        case .CBOR_DESERIALIZATION_FAILED: return "CBOR deserialization failed"
        case .CWT_EXPIRED: return "CWT expired"
        case .QR_CODE_ERROR: return "QR code error"
        case .CERTIFICATE_QUERY_FAILED: return "Signing certificate query failed"
        case .USER_CANCELLED: return "User cancelled"
        case .TRUST_SERVICE_ERROR: return "Trust Service Error"
        case .KEY_NOT_IN_TRUST_LIST: return "Key not in trust list"
        case .PUBLIC_KEY_EXPIRED: return "Public key expired"
        case .UNSUITABLE_PUBLIC_KEY_TYPE: return "Key unsuitable for EHN certificate type"
        case .KEY_CREATION_ERROR: return "Cannot create key from data"
        case .SIGNATURE_INVALID: return "Signature is not valid"
        case .KEYSTORE_ERROR: return "Keystore error"
        }
    }
}
