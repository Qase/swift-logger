//
//  LogEntryEncoder.swift
//  
//
//  Created by Radek Čep on 23.02.2022.
//

import Foundation

public struct LogEntryEncoder: LogEntryEncoding {
    private let logFileRecordSeparator: String
    private let logHeaderOpeningSeparator: String
    private let logHeaderClosingSeparator: String
    private let logLocationSeparator: String
    private let lineIdentifier: String
    private let messageSeparator: String
    private let dateFormatter: DateFormatter

    public init(
        logFileRecordSeparator: String = Constants.Separators.logFileRecordSeparator,
        logHeaderOpeningSeparator: String = Constants.Separators.logHeaderOpeningSeparator,
        logHeaderClosingSeparator: String = Constants.Separators.logHeaderClosingSeparator,
        logLocationSeparator: String = Constants.Separators.logLocationSeparator,
        lineIdentifier: String = Constants.Separators.lineSeparator,
        messageSeparator: String = Constants.Separators.messageSeparator,
        dateFormatter: DateFormatter = DateFormatter.dateTimeFormatter
    ) {
        self.logFileRecordSeparator = logFileRecordSeparator
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

        return "\(logFileRecordSeparator) \(header) \(location)\(Constants.Separators.messageSeparator) \(logEntry.message)"
    }
}
