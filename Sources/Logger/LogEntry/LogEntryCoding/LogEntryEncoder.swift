//
//  LogEntryEncoder.swift
//  
//
//  Created by Radek Čep on 23.02.2022.
//

import Foundation

public struct LogEntryEncoder: LogEntryEncoding {
    private let logEntryConfig: LogEntryConfig

    public init(
        logEntryConfig: LogEntryConfig = .init()
    ) {
        self.logEntryConfig = logEntryConfig
    }

    public func encode(_ logEntry: LogEntry) -> String {
        let level = logEntry.header.level.rawValue
        let date = logEntryConfig.dateFormatter.string(from: logEntry.header.date)

        let fileName = logEntry.location.fileName
        let function = logEntry.location.function
        let line = logEntry.location.line

        let header = "\(logEntryConfig.logHeaderOpeningSeparator)\(level) \(date)\(logEntryConfig.logHeaderClosingSeparator)"

        let logLocationSeparator = logEntryConfig.logLocationSeparator
        let location = "\(fileName) \(logLocationSeparator) \(function) \(logLocationSeparator) \(logEntryConfig.lineIdentifier) \(line)"

        return "\(logEntryConfig.logRecordSeparator) \(header) \(location)\(logEntryConfig.messageSeparator) \(logEntry.message)"
    }
}
