//
//  LogEntryEncoder.swift
//  
//
//  Created by Radek Čep on 23.02.2022.
//

import Foundation

public struct LogEntryEncoder: LogEntryEncoding {
    private let logRecordSeparator: String
    private let logHeaderOpeningSeparator: String
    private let logHeaderClosingSeparator: String
    private let logLocationSeparator: String
    private let lineIdentifier: String
    private let messageSeparator: String
    private let dateFormatter: DateFormatter

    public init(
        logRecordSeparator: String = "|>",
        logHeaderOpeningSeparator: String = "[~",
        logHeaderClosingSeparator: String = "~]",
        logLocationSeparator: String = "—",
        lineIdentifier: String = "line",
        messageSeparator: String = ":",
        dateFormatter: DateFormatter = DateFormatter.dateTimeFormatter
    ) {
        self.logRecordSeparator = logRecordSeparator
        self.logHeaderOpeningSeparator = logHeaderOpeningSeparator
        self.logHeaderClosingSeparator = logHeaderClosingSeparator
        self.logLocationSeparator = logLocationSeparator
        self.lineIdentifier = lineIdentifier
        self.messageSeparator = messageSeparator
        self.dateFormatter = dateFormatter
    }

    public func encode(_ logEntry: LogEntry) -> String {
        let level = logEntry.header.level.rawValue
        let date = dateFormatter.string(from: logEntry.header.date)

        let fileName = logEntry.location.fileName
        let function = logEntry.location.function
        let line = logEntry.location.line

        let header = "\(logHeaderOpeningSeparator)\(level) \(date)\(logHeaderClosingSeparator)"
        let location = "\(fileName) \(logLocationSeparator) \(function) \(logLocationSeparator) \(lineIdentifier) \(line)"

        return "\(logRecordSeparator) \(header) \(location)\(messageSeparator) \(logEntry.message)"
    }
}
