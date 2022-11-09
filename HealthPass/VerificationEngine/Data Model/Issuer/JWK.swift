//
//  JWK.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import CryptoKit

public enum JWKError: Error {
    case missingKTYComponent
    case missingXComponent
    case missingYComponent
    // Elliptic curve (EC) keys should usually be the only type expected.
    case incorrectKeyType(expected: String, actual: String)
    case unsupportedCurve(crv: String?)
    case keyWithIDNotFound(String)
}

public struct JWKSet: Codable {
    
    public let keys: [JWK]
   
    public let name: String?
    public let url: String?

    /// Returns the key with the given id, if found. If not throws `JWKError.keyWithIDNotFound`.
    public func key(with id: String) throws -> JWK {
        guard let key = keys.first(where: { $0.kid == id }) else {
            throw JWKError.keyWithIDNotFound(id)
        }
        return key
    }
}

/**
 A JSON Web Key (JWK) is a JavaScript Object Notation (JSON) data
 structure that represents a cryptographic key.  This specification
 also defines a JWK Set JSON data structure that represents a set of
 JWKs.  Cryptographic algorithms and identifiers for use with this
 specification are described in the separate JSON Web Algorithms (JWA)
 specification and IANA registries established by that specification.
 
 Examples -
 
 o Symmetric Keys, Octet sequence key
 -
 {
 "kty" : "oct",
 "kid" : "0afee142-a0af-4410-abcc-9f2d44ff45b5",
 "alg" : "HS256",
 "k"   : "FdFYFzERwC2uCBB46pZQi4GG85LujR8obt-KWRBICVQ"
 }
 
 o Symmetric Keys, Octet key pair
 -
 {
 "kty" : "OKP",
 "crv" : "Ed25519",
 "x"   : "11qYAYKxCrfVS_7TyWQHOg7hcvPapiMlrwIaaPcHURo",
 "d"   : "nWGxne_9WmC6hEr0kuwsxERJxWl7MmkZcDusAxyuf2A",
 "use" : "sig",
 "kid" : "FdFYFzERwC2uCBB46pZQi4GG85LujR8obt-KWRBICVQ"
 }
 
 o RSA Private Key, Plaintext
 -
 {
 "kty" : "RSA",
 "kid" : "cc34c0a0-bd5a-4a3c-a50d-a2a7db7643df",
 "use" : "sig",
 "n"   : "pjdss8ZaDfEH6K6U7GeW2nxDqR4IP049fk1fK0lndimbMMVBdPv_hSpm8T8EtBDxrUdi1OHZfMhUixGaut-3nQ4GG9nM249oxhCtxqqNvEXrmQRGqczyLxuh-fKn9Fg--hS9UpazHpfVAFnB5aCfXoNhPuI8oByyFKMKaOVgHNqP5NBEqabiLftZD3W_lsFCPGuzr4Vp0YS7zS2hDYScC2oOMu4rGU1LcMZf39p3153Cq7bS2Xh6Y-vw5pwzFYZdjQxDn8x8BG3fJ6j8TGLXQsbKH1218_HcUJRvMwdpbUQG5nvA2GXVqLqdwp054Lzk9_B_f1lVrmOKuHjTNHq48w",
 "e"   : "AQAB",
 "d"   : "ksDmucdMJXkFGZxiomNHnroOZxe8AmDLDGO1vhs-POa5PZM7mtUPonxwjVmthmpbZzla-kg55OFfO7YcXhg-Hm2OWTKwm73_rLh3JavaHjvBqsVKuorX3V3RYkSro6HyYIzFJ1Ek7sLxbjDRcDOj4ievSX0oN9l-JZhaDYlPlci5uJsoqro_YrE0PRRWVhtGynd-_aWgQv1YzkfZuMD-hJtDi1Im2humOWxA4eZrFs9eG-whXcOvaSwO4sSGbS99ecQZHM2TcdXeAs1PvjVgQ_dKnZlGN3lTWoWfQP55Z7Tgt8Nf1q4ZAKd-NlMe-7iqCFfsnFwXjSiaOa2CRGZn-Q",
 "p"   : "4A5nU4ahEww7B65yuzmGeCUUi8ikWzv1C81pSyUKvKzu8CX41hp9J6oRaLGesKImYiuVQK47FhZ--wwfpRwHvSxtNU9qXb8ewo-BvadyO1eVrIk4tNV543QlSe7pQAoJGkxCia5rfznAE3InKF4JvIlchyqs0RQ8wx7lULqwnn0",
 "q"   : "ven83GM6SfrmO-TBHbjTk6JhP_3CMsIvmSdo4KrbQNvp4vHO3w1_0zJ3URkmkYGhz2tgPlfd7v1l2I6QkIh4Bumdj6FyFZEBpxjE4MpfdNVcNINvVj87cLyTRmIcaGxmfylY7QErP8GFA-k4UoH_eQmGKGK44TRzYj5hZYGWIC8",
 "dp"  : "lmmU_AG5SGxBhJqb8wxfNXDPJjf__i92BgJT2Vp4pskBbr5PGoyV0HbfUQVMnw977RONEurkR6O6gxZUeCclGt4kQlGZ-m0_XSWx13v9t9DIbheAtgVJ2mQyVDvK4m7aRYlEceFh0PsX8vYDS5o1txgPwb3oXkPTtrmbAGMUBpE",
 "dq"  : "mxRTU3QDyR2EnCv0Nl0TCF90oliJGAHR9HJmBe__EjuCBbwHfcT8OG3hWOv8vpzokQPRl5cQt3NckzX3fs6xlJN4Ai2Hh2zduKFVQ2p-AF2p6Yfahscjtq-GY9cB85NxLy2IXCC0PF--Sq9LOrTE9QV988SJy_yUrAjcZ5MmECk",
 "qi"  : "ldHXIrEmMZVaNwGzDF9WG8sHj2mOZmQpw9yrjLK9hAsmsNr5LTyqWAqJIYZSwPTYWhY4nu2O0EY9G9uYiqewXfCKw_UngrJt8Xwfq1Zruz0YY869zPN4GiE9-9rzdZB33RBw8kIOquY3MK74FMwCihYx_LiU2YTHkaoJ3ncvtvg"
 }
 
 o RSA Private Key, X.509 Certificate Chain
 -
 {"kty":"RSA",
 "use":"sig",
 "kid":"1b94c",
 "n":"vrjOfz9Ccdgx5nQudyhdoR17V-IubWMeOZCwX_jj0hgAsz2J_pqYW08
 PLbK_PdiVGKPrqzmDIsLI7sA25VEnHU1uCLNwBuUiCO11_-7dYbsr4iJmG0Q
 u2j8DsVyT1azpJC_NG84Ty5KKthuCaPod7iI7w0LK9orSMhBEwwZDCxTWq4a
 YWAchc8t-emd9qOvWtVMDC2BXksRngh6X5bUYLy6AyHKvj-nUy1wgzjYQDwH
 MTplCoLtU-o-8SNnZ1tmRoGE9uJkBLdh5gFENabWnU5m1ZqZPdwS-qo-meMv
 VfJb6jJVWRpl2SUtCnYG2C32qvbWbjZ_jBPD5eunqsIo1vQ",
 "e":"AQAB",
 "x5c":
 ["MIIDQjCCAiqgAwIBAgIGATz/FuLiMA0GCSqGSIb3DQEBBQUAMGIxCzAJB
 gNVBAYTAlVTMQswCQYDVQQIEwJDTzEPMA0GA1UEBxMGRGVudmVyMRwwGgYD
 VQQKExNQaW5nIElkZW50aXR5IENvcnAuMRcwFQYDVQQDEw5CcmlhbiBDYW1
 wYmVsbDAeFw0xMzAyMjEyMzI5MTVaFw0xODA4MTQyMjI5MTVaMGIxCzAJBg
 NVBAYTAlVTMQswCQYDVQQIEwJDTzEPMA0GA1UEBxMGRGVudmVyMRwwGgYDV
 QQKExNQaW5nIElkZW50aXR5IENvcnAuMRcwFQYDVQQDEw5CcmlhbiBDYW1w
 YmVsbDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL64zn8/QnH
 YMeZ0LncoXaEde1fiLm1jHjmQsF/449IYALM9if6amFtPDy2yvz3YlRij66
 s5gyLCyO7ANuVRJx1NbgizcAblIgjtdf/u3WG7K+IiZhtELto/A7Fck9Ws6
 SQvzRvOE8uSirYbgmj6He4iO8NCyvaK0jIQRMMGQwsU1quGmFgHIXPLfnpn
 fajr1rVTAwtgV5LEZ4Iel+W1GC8ugMhyr4/p1MtcIM42EA8BzE6ZQqC7VPq
 PvEjZ2dbZkaBhPbiZAS3YeYBRDWm1p1OZtWamT3cEvqqPpnjL1XyW+oyVVk
 aZdklLQp2Btgt9qr21m42f4wTw+Xrp6rCKNb0CAwEAATANBgkqhkiG9w0BA
 QUFAAOCAQEAh8zGlfSlcI0o3rYDPBB07aXNswb4ECNIKG0CETTUxmXl9KUL
 +9gGlqCz5iWLOgWsnrcKcY0vXPG9J1r9AqBNTqNgHq2G03X09266X5CpOe1
 zFo+Owb1zxtp3PehFdfQJ610CDLEaS9V9Rqp17hCyybEpOGVwe8fnk+fbEL
 2Bo3UPGrpsHzUoaGpDftmWssZkhpBJKVMJyf/RuP2SmmaIzmnw9JiSlYhzo
 4tpzd5rFXhjRbg4zW9C+2qok+2+qDM1iJ684gPHMIY8aLWrdgQTxkumGmTq
 gawR+N5MDtdPTEQ0XfIBc2cJEUyMTY5MPvACWpkA6SdS4xSvdXK3IVfOWA=="]
 }
 
 o JWK, EC P-256 key pair
 -
 {
 "kty" : "EC",
 "crv" : "P-256",
 "x"   : "SVqB4JcUD6lsfvqMr-OKUNUphdNn64Eay60978ZlL74",
 "y"   : "lf0u0pMj4lGAzZix5u4Cm5CMQIgMNpkwy163wtKYVKI",
 "d"   : "0g5vAEKzugrXaRbgKG0Tj2qJ5lMP4Bezds1_sTybkfk"
 }
 */
public struct JWK: Codable {
    
    /**
     The "kty" (key type) parameter identifies the cryptographic algorithm
     family used with the key, such as "RSA" or "EC".  "kty" values should
     either be registered in the IANA "JSON Web Key Types" registry
     established by [JWA] or be a value that contains a Collision-
     Resistant Name.  The "kty" value is a case-sensitive string.  This
     member MUST be present in a JWK.
     
     A list of defined "kty" values can be found in the IANA "JSON Web Key
     Types" registry established by [JWA]; the initial contents of this
     registry are the values defined in Section 6.1 of [JWA].
     
     The key type definitions include specification of the members to be
     used for those key types.  Members used with specific "kty" values
     can be found in the IANA "JSON Web Key Parameters" registry
     established by Section 8.1.
     */
    public let kty: String?
    public let crv: String?
    
    /**
     The "alg" (algorithm) parameter identifies the algorithm intended for
     use with the key.  The values used should either be registered in the
     IANA "JSON Web Signature and Encryption Algorithms" registry
     established by [JWA] or be a value that contains a Collision-
     Resistant Name.  The "alg" value is a case-sensitive ASCII string.
     Use of this member is OPTIONAL.
     */
    public let alg: String?
    public let ext: Bool?
    
    /**
     The "kid" (key ID) parameter is used to match a specific key.  This
     is used, for instance, to choose among a set of keys within a JWK Set
     during key rollover.  The structure of the "kid" value is
     unspecified.  When "kid" values are used within a JWK Set, different
     keys within the JWK Set SHOULD use distinct "kid" values.  (One
     example in which different keys might use the same "kid" value is if
     they have different "kty" (key type) values but are considered to be
     equivalent alternatives by the application using them.)  The "kid"
     value is a case-sensitive string.  Use of this member is OPTIONAL.
     When used with JWS or JWE, the "kid" value is used to match a JWS or
     JWE "kid" Header Parameter value.
     */
    public let kid: String?
    
    /**
     The "key_ops" (key operations) parameter identifies the operation(s)
     for which the key is intended to be used.  The "key_ops" parameter is
     intended for use cases in which public, private, or symmetric keys
     may be present.
     
     Its value is an array of key operation values.  Values defined by
     this specification are:
     
     o  "sign" (compute digital signature or MAC)
     o  "verify" (verify digital signature or MAC)
     o  "encrypt" (encrypt content)
     o  "decrypt" (decrypt content and validate decryption, if applicable)
     o  "wrapKey" (encrypt key)
     o  "unwrapKey" (decrypt key and validate decryption, if applicable)
     o  "deriveKey" (derive key)
     o  "deriveBits" (derive bits not to be used as a key)
     
     (Note that the "key_ops" values intentionally match the "KeyUsage"
     values defined in the Web Cryptography API
     [W3C.CR-WebCryptoAPI-20141211] specification.)
     
     Other values MAY be used.  The key operation values are case-
     sensitive strings.  Duplicate key operation values MUST NOT be
     present in the array.  Use of the "key_ops" member is OPTIONAL,
     unless the application requires its presence.
     
     Multiple unrelated key operations SHOULD NOT be specified for a key
     because of the potential vulnerabilities associated with using the
     same key with multiple algorithms.  Thus, the combinations "sign"
     with "verify", "encrypt" with "decrypt", and "wrapKey" with
     "unwrapKey" are permitted, but other combinations SHOULD NOT be used.
     
     Additional "key_ops" (key operations) values can be registered in the
     IANA "JSON Web Key Operations" registry established by Section 8.3.
     The same considerations about registering extension values apply to
     the "key_ops" member as do for the "use" member.
     
     The "use" and "key_ops" JWK members SHOULD NOT be used together;
     however, if both are used, the information they convey MUST be
     consistent.  Applications should specify which of these members they
     use, if either is to be used by the application.
     */
    public let keyOps: [String]?
    
    /**
     The "use" (public key use) parameter identifies the intended use of
     the public key.  The "use" parameter is employed to indicate whether
     a public key is used for encrypting data or verifying the signature
     on data.
     
     Values defined by this specification are:
     
     o  "sig" (signature)
     o  "enc" (encryption)
     
     Other values MAY be used.  The "use" value is a case-sensitive
     string.  Use of the "use" member is OPTIONAL, unless the application
     requires its presence.
     
     When a key is used to wrap another key and a public key use
     designation for the first key is desired, the "enc" (encryption) key
     use value is used, since key wrapping is a kind of encryption.  The
     "enc" value is also to be used for public keys used for key agreement
     operations.
     
     Additional "use" (public key use) values can be registered in the
     IANA "JSON Web Key Use" registry established by Section 8.2.
     Registering any extension values used is highly recommended when this
     specification is used in open environments, in which multiple
     organizations need to have a common understanding of any extensions
     used.  However, unregistered extension values can be used in closed
     environments, in which the producing and consuming organization will
     always be the same.
     */
    public let use: String?
    
    /**
     The key value. It is represented as the Base64URL encoding of value's big endian representation.
     */
    public let k: String?
    
    /**
     Degree of Curve
     */
    public let d: String?
    
    /**
     represented as 2048-bit hexadecimal integer modulus
     */
    public let n: String?
    
    /**
     24-bit public exponent
     */
    public let e: String?
    
    
    /**
     p prime factors
     */
    public let p: String?
    
    /**
     q prime factors
     */
    public let q: String?
    
    /**
     dq CRT exponents
     */
    public let dp: String?
   
    /**
     dQ CRT exponents
     */
    public let dq: String?
    
    /**
     qi CRT coefficient
     */
    public let qi: String?
    
    
    /**
     x coordinate on graph for the curve
     */
    public let x: String?
    /**
     y coordinate on graph for the curve
     */
    public let y: String?
    
    
    // MARK: Initialization
    
    public init?(value: [String: Any]) {
        kty = value["kty"] as? String
        crv = value["crv"] as? String
        alg = value["alg"] as? String
        ext = value["ext"] as? Bool
        kid = value["kid"] as? String
        keyOps = value["keyOps"] as? [String]
        use = value["use"] as? String
        
        k = value["k"] as? String
        d = value["d"] as? String
        n = value["n"] as? String
        e = value["e"] as? String
        p = value["p"] as? String
        q = value["q"] as? String
        
        dp = value["dp"] as? String
        dq = value["dq"] as? String
        qi = value["qi"] as? String
        
        x = value["x"] as? String
        y = value["y"] as? String
    }
    
    
    // MARK: Conversion
    
    /// Returns the public key as a `Data` instance.
    public func asP256PublicKey() throws -> P256.Signing.PublicKey {
        guard let kty = kty else {
            throw JWKError.missingKTYComponent
        }
        
        guard kty == "EC" else {
            throw JWKError.incorrectKeyType(expected: "EC", actual: kty)
        }
        
        guard crv == "P-256" else {
            throw JWKError.unsupportedCurve(crv: crv)
        }
        
        let rawKey = try asRawPublicKey()
        return try P256.Signing.PublicKey(rawRepresentation: rawKey)
    }
    
    private func asRawPublicKey() throws -> Data {
        guard let x = x else {
            throw JWKError.missingXComponent
        }
        
        guard let y = y else {
            throw JWKError.missingYComponent
        }
        
        let xData = try Base64URL.decode(x)
        let yData = try Base64URL.decode(y)
        let pubkey = xData + yData
        return pubkey
    }
}

