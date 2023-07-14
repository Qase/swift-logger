import Foundation
import OSLog

/// Logger using Apple unified logging API
/// https://developer.apple.com/documentation/os/logger
public class UnifiedLogger: Logging {
    let bundleIdentifier: String
    private let logEntryEncoder: LogEntryEncoding
    private let unifiedLogger: (OSLogType, String) -> Void

    public var levels: [Level] = Level.allCases

    public convenience init(
        bundleIdentifier: String,
        category: String,
        logEntryEncoder: LogEntryEncoding = LogEntryEncoder()
    ) {
        let logger = Logger(subsystem: bundleIdentifier, category: category)
        self.init(
            bundleIdentifier: bundleIdentifier,
            unifiedLogger: { logger.log(level: $0, "\($1, privacy: .public)") },
            logEntryEncoder: logEntryEncoder
        )
    }

    init(
        bundleIdentifier: String,
        unifiedLogger: @escaping ((OSLogType, String) -> Void),
        logEntryEncoder: LogEntryEncoding = LogEntryEncoder()
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.logEntryEncoder = logEntryEncoder
        self.unifiedLogger = unifiedLogger
    }

    public func log(_ logEntry: LogEntry) {
        unifiedLogger(logEntry.header.level.osLogType, "\(self.logEntryEncoder.encode(logEntry))")
    }
}
