//
//  LogEntry+mock.swift
//  
//
//  Created by Martin Troup on 23.11.2021.
//

import Foundation
@testable import Logger

extension LogEntry {
    static func mock(_ message: String) -> LogEntry {
        .init(
            header: .init(date: Date(), level: .info, dateFormatter: DateFormatter.monthsDaysTimeFormatter),
            location: .init(fileName: "file", function: "function", line: 1),
            message: message
        )
    }
}
