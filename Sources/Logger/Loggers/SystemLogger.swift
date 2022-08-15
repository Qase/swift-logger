//
//  SystemLogger.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation
import os

/// Pre-built logger that wraps system os_logger
public class SystemLogger: Logging {
    private let logEntryEncoder: LogEntryEncoding
    private let prefix: String
    private var logger: OSLog

    public init(
        subsystem: String,
        category: String,
        logEntryEncoder: LogEntryEncoding = LogEntryEncoder(),
        prefix: String = ""
    ) {
        self.logEntryEncoder = logEntryEncoder
        self.logger = OSLog(subsystem: subsystem, category: category)
        self.prefix = prefix
    }

    public var levels: [Level] = [.info]

    public func log(_ logEntry: LogEntry) {
        os_log(
            "%@",
            log: logger,
            type: logEntry.header.level.logType,
            createMessageWithPrefix(logEntry)
        )
    }

    public func createMessageWithPrefix(_ logEntry: LogEntry) -> String {
        "\(prefix):\(logEntryEncoder.encode(logEntry))"
    }
}

private extension Level {
    var logType: OSLogType {
        switch self {
        case .info:
            return .info
        case .debug:
            return .debug
        case .verbose, .warn, .error, .custom:
            return .default
        case .system:
            return .fault
        case .process:
            return .error
        }
    }
}
