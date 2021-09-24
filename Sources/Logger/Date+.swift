//
//  Date+.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation

extension Date {

    /// Method to return String in format: "yyyy-MM-dd HH:mm:ss" from Date instance.
    ///
    /// - Returns: String
    func toFullDateTimeString() -> String {
        DateHelper.toFullDateTimeString(from: self)
    }

    /// Method to return String in format: "yyyy-MM-dd" from Date instance.
    ///
    /// - Returns: String
    func toFullDateString() -> String {
        DateHelper.toFullDateString(from: self)
    }
}

private struct DateHelper {
    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func toFullDateTimeString(from date: Date) -> String {
        DateHelper.dateTimeFormatter.string(from: date)
    }

    static func toFullDateString(from date: Date) -> String {
        DateHelper.dateFormatter.string(from: date)
    }
}
