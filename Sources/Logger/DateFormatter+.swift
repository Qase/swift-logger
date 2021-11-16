//
//  Date+.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation

extension DateFormatter {
    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let monthsDaysTimeFormatter: DateFormatter = {
         let formatter = DateFormatter()

         formatter.locale = Locale.current
         formatter.dateFormat = "MM-dd HH:mm:ss.SSS"
         return formatter
     }()
}
