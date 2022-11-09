//
//  DataStore+Metrics.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

enum MetricsUploadCount: Int {
    case one = 1
    case hundred = 100
    case fiveHundred = 500
    case thousand = 1000
    
    var displayValue: String {
        switch self {
        case .one: return "1"
        case .hundred: return "100"
        case .fiveHundred: return "500"
        case .thousand: return "1000"
        }
    }
}

enum MetricsUploadTime: TimeInterval {
    case oneMin = 60
    case oneHour = 3600
    case twoHours = 7200
    case fourHours = 14400
    
    var displayValue: String {
        switch self {
        case .oneMin: return "1 Min".localized
        case .oneHour: return "1 Hour".localized
        case .twoHours: return "2 Hours".localized
        case .fourHours: return "4 Hours".localized
        }
    }
}

extension DataStore {
    
    static let MetricsUploadLimitCount: Int = MetricsUploadCount.hundred.rawValue
    static let MetricsUploadLimitTimeInterval: TimeInterval = MetricsUploadTime.oneHour.rawValue
    
    mutating func addMetric(metric: Metric) {
        guard allMetricsDictionary != nil else {
            allMetricsDictionary = [metric.rawDictionary]
            return
        }
        
        allMetricsDictionary?.append(metric.rawDictionary)
    }
    
    mutating func deleteAllMetrics() {
        allMetricsDictionary = nil
    }
    
    func getAggregatedMetricsString() -> String? {
        guard let aggregatedData = getAggregatedMetricsData() else {
            return nil
        }
        
        guard let aggregatedString = String(data: aggregatedData, encoding: String.Encoding.utf8) else {
            return nil
        }
        
        return aggregatedString
    }
    
    func getAggregatedMetricsData() -> Data? {
        guard let aggregatedJSON = getAggregatedMetricsDictionary() else {
            return nil
        }
        
        guard let aggregatedData = try? JSONSerialization.data(withJSONObject: aggregatedJSON, options: [.sortedKeys]) else {
            return nil
        }
        
        return aggregatedData
    }
    
    func getAggregatedMetricsDictionary() -> [[String: Any?]]? {
        guard let allMetrics = DataStore.shared.allMetrics, !(allMetrics.isEmpty) else {
            return nil
        }
        
        let allMetricsMap = allMetrics.compactMap({ $0.rawDictionary })
        let uniqueMetricsSet = Set(allMetricsMap)
        
        let aggregatedJSON = uniqueMetricsSet.map ({ dictionary -> [String: Any?] in
            guard let metric = Metric(value: dictionary) else {
                return [:]
            }
            
            let count = allMetrics.filter({
                ($0.verifierId == metric.verifierId &&
                    $0.organizationId == metric.organizationId &&
                    $0.customerId == metric.customerId &&
                    $0.issuerId == metric.issuerId &&
                    $0.type == metric.type &&
                    $0.spec == metric.spec &&
                    $0.status == metric.status &&
                    $0.timestamp == metric.timestamp)
            }).count
            
            let scans: [String: Any?] = [ "issuerDID": metric.issuerId,
                                          "issuerName": metric.issuerName,
                                          "credentialType": metric.type,
                                          "credentialSpec": metric.spec,
                                          "scanResult": metric.status,
                                          "datetime": metric.timestamp,
                                          "total": count ]
            
            let json: [String: Any?] = [ "verDID": metric.verifierId,
                                         "orgId": metric.organizationId,
                                         "customerId": metric.customerId,
                                         "scans": [ scans ]
            ]
            
            return json
        })
        
        return aggregatedJSON
    }
    
}
