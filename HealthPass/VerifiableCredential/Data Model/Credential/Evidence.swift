//
//  Evidence.swift
//  VerifiableCredential
//
//  Created by Iryna Horbachova on 27.07.2021.
//

import Foundation

// MARK: - Evidence

public struct Evidence: Codable {
    enum CodingKeys: String, CodingKey {
        case feedbackURL = "feedbackUrl"
        case infoURL = "infoUrl"
    }
    // ======================================================================
    // MARK: - Public
    // ======================================================================
    
    // MARK: - Public Properties
    
    public var id: String?
    public var feedbackURL: String?
    public var infoURL:  String?
    public var type: [String]?
    public var batch: String?
    public var vaccine: String?
    public var manufacturer: String?
    public var date: String?
    public var effectiveStart: String?
    public var effectiveUntil: String?
    public var dose: Int?
    public var totalDoses: Int?
    public var verifier: [String: Any]?
    public var facility: [String: Any]?
}


