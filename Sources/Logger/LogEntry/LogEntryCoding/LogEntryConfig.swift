//
//  LogEntryConfig.swift
//  
//
//  Created by Radek Čep on 02.03.2022.
//

import Foundation

public struct LogEntryConfig {
    let logRecordSeparator: String
    let logHeaderOpeningSeparator: String
    let logHeaderClosingSeparator: String
    let logLocationSeparator: String
    let lineIdentifier: String
    let messageSeparator: String
    let dateFormatter: DateFormatter

    public init(
        logRecordSeparator: String = "|>",
        logHeaderOpeningSeparator: String = "[",
        logHeaderClosingSeparator: String = "]",
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
}
