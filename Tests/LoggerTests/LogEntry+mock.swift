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
        LogEntry(
            header: LogHeader(date: Date(), level: .info),
            location: LogLocation(fileName: "file", function: "function", line: 1),
            message: message
        )
    }
}
