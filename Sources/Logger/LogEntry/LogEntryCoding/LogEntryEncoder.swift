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

    public func encode(_ logEntry: LogEntry, verbose: Bool) -> String {
        if verbose {
            return verboseMessage(logEntry)
        } else {
            return plainMessage(logEntry)
        }
    }

    private func plainMessage(_ logEntry: LogEntry) -> String {
        let level = logEntry.header.level.description

        let messageSeparator = logEntryConfig.messageSeparator
        let logLocationSeparator = logEntryConfig.logLocationSeparator
        let lineIdentifier = logEntryConfig.lineIdentifier

        let fileName = logEntry.location.fileName
        let function = logEntry.location.function
        let line = logEntry.location.line

        let location = "\(fileName) \(logLocationSeparator) \(function) \(logLocationSeparator) \(lineIdentifier) \(line)"

        return "\(level) \(location)\(messageSeparator) \(logEntry.message)"
    }

    private func verboseMessage(_ logEntry: LogEntry) -> String {
        let level = logEntry.header.level.rawValue
        let date = logEntryConfig.dateFormatter.string(from: logEntry.header.date)

        let messageSeparator = logEntryConfig.messageSeparator
        let logLocationSeparator = logEntryConfig.logLocationSeparator
        let lineIdentifier = logEntryConfig.lineIdentifier

        let fileName = logEntry.location.fileName
        let function = logEntry.location.function
        let line = logEntry.location.line

        let header = "\(logEntryConfig.logHeaderOpeningSeparator)\(level) \(date)\(logEntryConfig.logHeaderClosingSeparator)"
        let location = "\(fileName) \(logLocationSeparator) \(function) \(logLocationSeparator) \(lineIdentifier) \(line)"

        return "\(logEntryConfig.logRecordSeparator) \(header) \(location)\(messageSeparator) \(logEntry.message)"
    }
}
