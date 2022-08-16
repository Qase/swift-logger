//
//  SystemLogger.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation
import OSLog

/// Pre-built logger that wraps system os_logger
public class SystemLogger: Logging {
    private let logEntryEncoder: LogEntryEncoding
    private let prefix: String
    private let systemLogger: (OSLogType, String) -> Void

    public init(
        subsystem: String,
        category: String,
        logEntryEncoder: LogEntryEncoding = LogEntryEncoder(),
        prefix: String = "",
        systemLogger: ((OSLogType, String) -> Void)? = nil
    ) {
        self.logEntryEncoder = logEntryEncoder
        self.prefix = prefix

        let logger = OSLog(subsystem: subsystem, category: category)
        self.systemLogger = systemLogger ?? { os_log("%@", log: logger, type: $0, $1) }
    }

    public var levels: [Level] = [.info]

    public func log(_ logEntry: LogEntry) {
        systemLogger(logEntry.header.level.logType, "\(prefix):\(logEntryEncoder.encode(logEntry))")
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
