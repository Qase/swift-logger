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

    public convenience init(
        subsystem: String,
        category: String,
        logEntryEncoder: LogEntryEncoding = LogEntryEncoder(),
        prefix: String = ""
    ) {
        let logger = OSLog(subsystem: subsystem, category: category)
        self.init(
            systemLogger: { os_log("%{public}@", log: logger, type: $0, $1) },
            logEntryEncoder: logEntryEncoder,
            prefix: prefix
        )
    }

    init(
        systemLogger: @escaping ((OSLogType, String) -> Void),
        logEntryEncoder: LogEntryEncoding = LogEntryEncoder(),
        prefix: String = ""
    ) {
        self.logEntryEncoder = logEntryEncoder
        self.prefix = prefix
        self.systemLogger = systemLogger
    }

    public var levels: [Level] = [.info]

    public func log(_ logEntry: LogEntry) {
        systemLogger(logEntry.header.level.osLogType, "\(prefix):\(logEntryEncoder.encode(logEntry))")
    }
}
