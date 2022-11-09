//
//  Date+Utils.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

enum DateFormatPattern: String, CaseIterable {
    case defaultDate = "MM/dd/yyyy"
    case fullDate = "MMMM d, yyyy"
    case fullDateWithoutComma = "MMMM d yyyy"
    case shortDate = "MMM d, yyyy"
    case runningDate = "MMddyyyy"
    case runningYear = "yyyyMMdd"
    case shortYearFormat = "MM/dd/YY"
    case weekDayDate = "E, MMM d"
    case transactionShortDate = "MMdd"
    case depositDate = "yyMMdd"
    // 2016-11-30T23:59:59.000-05:00
    case updatingDate = "yyyy-MM-dd"
    case issueDate = "dd-MMM-yyyy"
    case receiptTranscationDate = "MM/dd/yy"
    case IBMDefault = "dd MMM yyyy"
    
    case defaultTime = "h:mm a"
    case meridianTimePattern = "a"
    case hourMinTimePattern = "h:mm"
    case hourMinSecTimePattern = "h:mm:ss"
    case militaryTimePattern = "HH:mm"
    
    case fullDateTime = "MMMM d, yyyy h:mm a"
    case longDateFormate = "yyyy-MM-dd HH:mm:ss ZZZ"
    case extendedDateFormate = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
    case timestampFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    case cacheTimeStampFormat = "yyyy-MM-dd, HH:mm:ss.SSSZ"
    case recentOrdersDate = "yyyy-MM-dd'T'HH:mm:ssZ"
    case transactionDate = "yyyy-MM-dd'T'HH:mm:ss"
    case dayDateTime = "E, MMM d yyyy h:mm a"
    case statusHealthFormat = "M/d/YY h:mm a"
    
    // 04/12/2019T02:45 PM
    case receiptDate = "MM/dd/yyyy'T'HH:mm:ss"
    
    case keyGenFormat = "MMM dd, yyyy hh:mm a"
    
    case credentialExpirationDateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z"
    
    case iOSDefault = "MM/dd/yyyy, HH:mm:ss.SSSZ"
    
}

extension Date {
    
    /**
     Returns a string for a given date
     
     :param: date (Required) The date to be converted to a string.
     :param: dateFormatPattern (Default) The date format of the required string
     
     :retruns: string for a given date
     
     :example:
     1.
     var dateString = NSDate.stringForDate(NSDate(), dateFormatPattern: .defaultTime)
     */
    static func stringForDate(date: Date, dateFormatPattern: DateFormatPattern = .timestampFormat, locale: Locale? = Locale.current) -> String {
        let dateFormatter = DateFormatter()
        
        if let locale = locale, let localizeDateFormat = DateFormatter.dateFormat(fromTemplate: dateFormatPattern.rawValue,
                                                                                  options: 0,
                                                                                  locale: locale) {
            dateFormatter.dateFormat = localizeDateFormat
        } else {
            dateFormatter.dateFormat = dateFormatPattern.rawValue
        }
        
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    /**
     Returns a date for a given string
     
     :param: string (Required) The string to be converted to a NSDate object.
     :param: dateFormatPattern (Default) The date format for the required date
     
     :retruns: date for a given string
     
     :example:
     1.
     var currentDate = dateFromString(String("6:30 AM"), dateFormatPattern: .defaultTime)
     */
    static func dateFromString(dateString: String, dateFormatPattern: DateFormatPattern? = .timestampFormat, locale: Locale? = nil) -> Date {
        let dateFormatter = DateFormatter()
        
        if let dateFormatPattern = dateFormatPattern {
            dateFormatter.dateFormat = dateFormatPattern.rawValue
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        
        let allDateFormat = DateFormatPattern.allCases.compactMap { $0.rawValue }
        
        for dateFormat in allDateFormat {
            dateFormatter.dateFormat = dateFormat
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        
        return Date()
    }
    
}

extension Date {
    
    // Convert local time to UTC (or GMT)
    func toUTCTime() -> Date {
        let timezone = TimeZone.current
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
    
    // Convert UTC (or GMT) to local time
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
    
}

/*
 case IBMDefault = "dd MMM yyyy"
 */

extension Date {
    
    func isOnlyDate(dateString: String, locale: Locale? = nil) -> Bool {
        let dateFormatter = DateFormatter()
        let allDateFormat = [DateFormatPattern.defaultDate,
                             DateFormatPattern.fullDate,
                             DateFormatPattern.fullDateWithoutComma,
                             DateFormatPattern.shortDate,
                             DateFormatPattern.runningDate,
                             DateFormatPattern.runningYear,
                             DateFormatPattern.weekDayDate,
                             DateFormatPattern.transactionShortDate,
                             DateFormatPattern.depositDate,
                             DateFormatPattern.updatingDate,
                             DateFormatPattern.issueDate,
                             DateFormatPattern.receiptTranscationDate,
                             DateFormatPattern.IBMDefault].compactMap { $0.rawValue }
        
        for dateFormat in allDateFormat {
            dateFormatter.dateFormat = dateFormat
            if let _ = dateFormatter.date(from: dateString) {
                return true
            }
        }
        
        return false
    }
    
    func isOnlyTime(timeString: String, locale: Locale? = nil) -> Bool {
        let timeFormatter = DateFormatter()
        let allTimeFormat = [DateFormatPattern.defaultTime,
                             DateFormatPattern.meridianTimePattern,
                             DateFormatPattern.hourMinTimePattern,
                             DateFormatPattern.hourMinSecTimePattern,
                             DateFormatPattern.militaryTimePattern].compactMap { $0.rawValue }
        
        for timeFormat in allTimeFormat {
            timeFormatter.dateFormat = timeFormat
            if let _ = timeFormatter.date(from: timeString) {
                return true
            }
        }
        
        return false
    }
    
}
