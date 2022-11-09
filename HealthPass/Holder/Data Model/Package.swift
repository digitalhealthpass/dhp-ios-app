//
//  Package.swift
//  HealthPass
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit
import QRCoder
import PromiseKit
import VerificationEngine

class Package {
    
    // MARK: - Internal
    var verifiableObject: VerifiableObject?
    var schema: Schema?
    var issuerMetadata: IssuerMetadata?
    
    var rawDictionary: [String: Any]?
    var rawString: Any?
    
    init(value: [String: Any]) {
        rawDictionary = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions()) as Data {
            rawString = String(data: jsonData, encoding: .utf8)
        }
        
        if let credentialString = value["credential"] as? String {
            verifiableObject = VerifiableObject(string: credentialString)
        }
        
        if let schemaString = value["schema"] as? String {
            schema = Schema(value: schemaString)
        }
        
        if let issuerMetadataString = value["issuerMetadata"] as? String {
            issuerMetadata = IssuerMetadata(value: issuerMetadataString)
        }
    }
}

extension Package {
    
    // Derived Data
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Properties
    
    var type: VCType {
        get {
            return verifiableObject?.type ?? .unknown
        }
    }
    
    var credential: Credential? {
        get {
            return verifiableObject?.credential
        }
    }
    
    var jws: JWS? {
        get {
            return verifiableObject?.jws
        }
    }
    
    var cose: Cose? {
        get {
            return verifiableObject?.cose
        }
    }
    
#if HOLDER
    
    var associatedContacts: [Contact]? {
        let userContacts = DataStore.shared.userContacts
        
        
        let contacts = userContacts.filter ({ contact in
            return contact.associatedUploadDetails?.associatedCredentials?.contains(where: { (id: String) -> Bool in
                if type == .IDHP || type == .GHP || type == .VC {
                    return credential?.id == id
                } else if type == .SHC {
                    return jws?.payload?.nbf == UInt64(id)
                } else if type == .DCC {
                    guard let cose = cose,
                          let cwt = CWT(from: cose.payload),
                          let certificateIdentifier = cwt.euHealthCert?.vaccinations?.first?.certificateIdentifier ?? cwt.euHealthCert?.recovery?.first?.certificateIdentifier ?? cwt.euHealthCert?.tests?.first?.certificateIdentifier else {
                              return false
                          }
                    
                    return certificateIdentifier == id
                }
                
                return false
            }) ?? false
            
        })
        
        return contacts
    }
    
#endif
    
    var issuanceDateValue: Date? {
        if type == .IDHP || type == .GHP || type == .VC {
            guard let issuanceDate = credential?.issuanceDate else {
                return nil
            }
            
            return Date.dateFromString(dateString: issuanceDate, dateFormatPattern: .credentialExpirationDateFormat)
        } else if type == .SHC {
            guard let issuanceDateTimeInterval = jws?.payload?.iat else {
                return nil
            }
            
            return Date(timeIntervalSince1970: TimeInterval(issuanceDateTimeInterval))
        } else if type == .DCC {
            guard let cose = cose else {
                return nil
            }
            
            guard let cwt = CWT(from: cose.payload) else {
                return nil
            }
            
            guard let expDateTimeInterval = cwt.iat else {
                return nil
            }
            
            return Date(timeIntervalSince1970: TimeInterval(expDateTimeInterval))
        }
        
        return nil
    }
    
    var expirationDateValue: Date? {
        if type == .IDHP || type == .GHP || type == .VC {
            guard let expirationDate = credential?.expirationDate else {
                return nil
            }
            
            return Date.dateFromString(dateString: expirationDate, dateFormatPattern: .credentialExpirationDateFormat)
        } else if type == .SHC {
            guard let expDateTimeInterval = jws?.payload?.exp else {
                return nil
            }
            
            return Date(timeIntervalSince1970: TimeInterval(expDateTimeInterval))
        } else if type == .DCC {
            guard let cose = cose else {
                return nil
            }
            
            guard let cwt = CWT(from: cose.payload) else {
                return nil
            }
            
            guard let expDateTimeInterval = cwt.exp else {
                return nil
            }
            
            return Date(timeIntervalSince1970: TimeInterval(expDateTimeInterval))
        }
        
        return nil
    }
    
    var isExpired: Bool {
        guard let expirationDateValue = expirationDateValue else {
            return false
        }
        
        let currentDate = Date()
        let order = Calendar.current.compare(currentDate, to: expirationDateValue, toGranularity: .second)
        return !(order == .orderedAscending)
    }
    
    // MARK: - VC Details
    var VCRecipientFullName: String? {
        guard let payload = verifiableObject?.payload as? [String: Any],
              let credentialSubject = payload["credentialSubject"] as? [String: Any] else {
            return nil
        }
    
        if let recipient = credentialSubject["recipient"] as? [String: Any] {
            var givenName = recipient["givenName"] as? String
            if isObfuscated(value: givenName) ?? true {
                givenName = getDeobfuscatedVaule(at: "recipient.givenName")
            }
            
            var familyName = recipient["familyName"] as? String
            if isObfuscated(value: familyName) ?? true {
                familyName = getDeobfuscatedVaule(at: "recipient.familyName")
            }
            
            return [givenName, familyName].compactMap { $0 }.joined(separator: " ")
        } else if let subject = credentialSubject["subject"] as? [String: Any], let name = subject["name"] as? [String: Any] {
            var givenName = name["given"] as? String
            if isObfuscated(value: givenName) ?? true {
                givenName = getDeobfuscatedVaule(at: "subject.name.given")
            }
            
            var familyName = name["family"] as? String
            if isObfuscated(value: familyName) ?? true {
                familyName = getDeobfuscatedVaule(at: "subject.name.family")
            }
            
            return [givenName, familyName].compactMap { $0 }.joined(separator: " ")
        }
        
        return nil
    }
    
    var VCRecipientDOB: String? {
        guard let payload = verifiableObject?.payload as? [String: Any],
              let credentialSubject = payload["credentialSubject"] as? [String: Any] else {
            return nil
        }

        if let recipient = credentialSubject["recipient"] as? [String: Any] {
            var birthDate = recipient["birthDate"] as? String
            if isObfuscated(value: birthDate) ?? true {
                birthDate = getDeobfuscatedVaule(at: "recipient.birthDate")
            }
            
            if let birthDateString = birthDate {
                let birthDate = Date.dateFromString(dateString: birthDateString)
                return Date.stringForDate(date: birthDate, dateFormatPattern: .IBMDefault)
            }
        } else if let subject = credentialSubject["subject"] as? [String: Any] {
            var birthDate = subject["birthDate"] as? String
            if isObfuscated(value: birthDate) ?? true {
                birthDate = getDeobfuscatedVaule(at: "subject.birthDate")
            }
            
            if let birthDateString = birthDate {
                let birthDate = Date.dateFromString(dateString: birthDateString)
                return Date.stringForDate(date: birthDate, dateFormatPattern: .IBMDefault)
            }
        }

        return nil
    }

    // MARK: - SHC Details
    
    var SHCRecipientFullName: String? {
        guard let json = verifiableObject?.payload as? [String: Any] else {
            return nil
        }
        
        return [getValue(at: "vc.credentialSubject.fhirBundle.entry[0].resource.name[0].given", for: json), getValue(at: "vc.credentialSubject.fhirBundle.entry[0].resource.name[0].family", for: json)].compactMap { $0 }.joined(separator: " ")
    }
    
    var SHCRecipientDOB: String? {
        guard let json = verifiableObject?.payload as? [String: Any] else {
            return nil
        }
        
        if let birthDateString = getValue(at: "vc.credentialSubject.fhirBundle.entry[0].resource.birthDate", for: json) {
            let birthDate = Date.dateFromString(dateString: birthDateString)
            return Date.stringForDate(date: birthDate, dateFormatPattern: .IBMDefault)
        }

        return nil
    }

    var SHCSchemaName: String? {
        return fetchSmartHealthSchema()
    }
    
    var SHCIssuerName: Promise<String?> {
        return Promise { resolver in
            self.fetchSHCIssuerDetails(bookmark: nil, resolver: resolver)
        }
    }
    
    var SHCColor: UIColor {
        return UIColor(hex: "#0072C3") ?? UIColor.black
    }
    
    // MARK: - DCC Details
    
    var DCCRecipientFullName: String? {
        guard let json = verifiableObject?.payload as? [String: Any] else {
            return nil
        }
        
        return [getValue(at: "nam.gn", for: json), getValue(at: "nam.fn", for: json)].compactMap { $0 }.joined(separator: " ")
    }
    
    var DCCRecipientDOB: String? {
        guard let json = verifiableObject?.payload as? [String: Any] else {
            return nil
        }
        
        if let birthDateString = getValue(at: "dob", for: json) {
            let birthDate = Date.dateFromString(dateString: birthDateString)
            return Date.stringForDate(date: birthDate, dateFormatPattern: .IBMDefault)
        }
        
        return nil
    }

    var DCCSchemaName: String? {
        return fetchEUDCCSchema()
    }
    
    var DCCIssuerName: String? {
        return fetchEUDCCIssuer()
    }
    
    var DCCColor: UIColor {
        return UIColor(hex: "#002D9C") ?? UIColor.black
    }
    
    // MARK: - Internal Methods
    
    func fetchQRCodeImage(size: CGSize? = nil,
                          color: UIColor = .black,
                          backgroundColor: UIColor = .white,
                          compressData: Bool? = nil,
                          completion: ((UIImage?, Error?) -> Void)) {
        
        guard let rawString = verifiableObject?.rawString else {
            completion(nil, nil)
            return
        }
        
        //Check if the credential is base64 decoded
        if let decodedData = Data(base64Encoded: rawString), let decodedString = String(data: decodedData, encoding: .utf8) {
            QRCodeEncoder().encode(for: decodedString,
                                      size: size,
                                      color: color,
                                      compressData: compressData,
                                      completion: completion)
        } else {
            QRCodeEncoder().encode(for: rawString,
                                      size: size,
                                      color: color,
                                      compressData: compressData,
                                      completion: completion)
        }
    }
    
    //MARK: - Private
    
    private func fetchSmartHealthSchema() -> String? {
        guard let vc = jws?.payload?.vc else {
            return nil
        }
        
        guard let types = vc.type else {
            return nil
        }
        
        let components = types.compactMap({ $0.components(separatedBy:"#").last?.capitalized })
        
        let schema = components.joined(separator: ", ")
        
        return schema
    }
    
    private func fetchSHCIssuerDetails(bookmark: String?, resolver: Resolver<String?>) {
        let unknownIssuer = String("Unknown Issuer")
        
        guard let issuerIdentifier = jws?.payload?.iss else {
            return resolver.fulfill(unknownIssuer)
        }
        
        //1. Check if the details can be found in cache
        if let jwkSet = DataStore.shared.getJWKSet(for: issuerIdentifier), !(jwkSet.isEmpty),
           let issuerName = jwkSet.compactMap({ $0.name }).first {
            return resolver.fulfill(issuerName)
        }
        
        //2. Invoke the API to get issuer details
        IssuerService().getGenericIssuer(issuerId: issuerIdentifier, type: .SHC) { result in
            switch result {
            case .success(let json):
                guard let payload = json["payload"] as? [[String : Any]], !(payload.isEmpty) else {
                    resolver.fulfill(unknownIssuer)
                    return
                }
                
                guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                      let jwkSet = try? JSONDecoder().decode([JWKSet].self, from: data) else {
                          resolver.fulfill(unknownIssuer)
                          return
                      }
                
                //3. Save the keys to cache
                DataStore.shared.addJWKSet(jwkSet: jwkSet)
                
                let filteredJwkSet = jwkSet.compactMap ({ return ($0.url == issuerIdentifier) ? $0 : nil })

                let issuer = filteredJwkSet.compactMap({ $0.name }).first ?? unknownIssuer
                resolver.fulfill(issuer)
                
            case .failure:
                resolver.fulfill(unknownIssuer)
            }
        }
    }
    
    private func fetchEUDCCSchema()  -> String? {
        guard let cose = verifiableObject?.cose,
              let cwt = CWT(from: cose.payload),
              let type = cwt.euHealthCert?.type else {
                  return nil
              }
        
        return type.displayValue
    }
    
    private func fetchEUDCCIssuer()  -> String {
        let unknownIssuer = String("Unknown Issuer")
        
        guard let cose = verifiableObject?.cose,
              let cwt = CWT(from: cose.payload),
              let iss = cwt.iss else {
                  return unknownIssuer
              }
        
        return Locale.current.localizedString(forRegionCode: iss) ?? iss
    }
    
    private func readJSONFromFile(fileName: String) -> Any? {
        var json: Any?
        if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
            do {
                let fileUrl = URL(fileURLWithPath: path)
                let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
                json = try? JSONSerialization.jsonObject(with: data)
            } catch {
                // Handle error here
            }
        }
        return json
    }
    
}

extension Package {
    
    private func getValue(at path: String, for json: [String: Any]) -> String? {
        var path = path.replacingOccurrences(of: "[", with: ".", options: .literal, range: nil)
        path = path.replacingOccurrences(of: "]", with: "", options: .literal, range: nil)
        
        let keys = path.components(separatedBy: ".")
        var trimmedValue: Any? = json
        
        var value: String?
        keys.forEach { key in
            
            if let index = Int(key) {
                guard let loopingValue = trimmedValue as? [Any], !(loopingValue.isEmpty), loopingValue.count > index else {
                    return
                }
                
                if keys.last == key {
                    let val = loopingValue[index]
                    if let directValue = val as? String {
                        value = directValue
                    } else if let arrayValue = val as? [Any] {
                        let stringArrayValue = arrayValue.compactMap{ String(describing: $0) }
                        value = stringArrayValue.joined(separator: " ")
                    } else if let dictionaryValue = val as? [String: Any], let data = try? JSONSerialization.data(withJSONObject: dictionaryValue, options: [.sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]) as Data {
                        value = String(data: data, encoding: .utf8)
                    } else {
                        value = String(describing: val)
                    }
                }
                
                trimmedValue = loopingValue[index]
            } else {
                let loopingValue: [String: Any]
                
                if let value = trimmedValue as? [String: Any], !(value.isEmpty) {
                    loopingValue = value
                } else if let value = trimmedValue as? [[String: Any]], !(value.isEmpty) {
                    loopingValue = value[0]
                } else {
                    return
                }
                
                if keys.last == key, let val = loopingValue[key] {
                    if let directValue = val as? String {
                        value = directValue
                    } else if let arrayValue = val as? [Any] {
                        let stringArrayValue = arrayValue.compactMap{ String(describing: $0) }
                        value = stringArrayValue.joined(separator: " ")
                    } else if let dictionaryValue = val as? [String: Any], let data = try? JSONSerialization.data(withJSONObject: dictionaryValue, options: [.sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]) as Data {
                        value = String(data: data, encoding: .utf8)
                    } else {
                        value = String(describing: val)
                    }
                }
                
                trimmedValue = loopingValue[key]
            }
        }
        
        return value
    }

    func isObfuscated(value: Any?) -> Bool? {
        guard let _ = value else {
            return nil
        }
        
        guard let obfuscatedString = value as? String else {
            // only string value can represent obfuscated values
            return false
        }
        
        let range = NSRange(location: 0, length: obfuscatedString.utf16.count)
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9_-]{42,43}$")
        return regex.firstMatch(in: obfuscatedString, options: [], range: range) != nil
    }

    func getDeobfuscatedVaule(at path: String) -> String? {
        guard let obfuscation = credential?.obfuscation else { return nil }
        
        guard let requiredObfuscation = obfuscation.filter({ $0.path == path }).first else { return nil }

        return requiredObfuscation.val
    }

}
