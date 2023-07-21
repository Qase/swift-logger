import Foundation
import OSLog

/// Logger using Apple unified logging API
/// https://developer.apple.com/documentation/os/logger
public class NativeLogger: Logging {
    let bundleIdentifier: String
    private let logEntryEncoder: LogEntryEncoding
    private let logger: (OSLogType, String) -> Void

    public var levels: [Level] = Level.allCases

    public convenience init(
        bundleIdentifier: String,
        category: String,
        logEntryEncoder: LogEntryEncoding = LogEntryEncoder()
    ) {
        let logger = Logger(subsystem: bundleIdentifier, category: category)
        self.init(
            bundleIdentifier: bundleIdentifier,
            logger: { logger.log(level: $0, "\($1, privacy: .public)") },
            logEntryEncoder: logEntryEncoder
        )
    }

    init(
        bundleIdentifier: String,
        logger: @escaping ((OSLogType, String) -> Void),
        logEntryEncoder: LogEntryEncoding = LogEntryEncoder()
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.logEntryEncoder = logEntryEncoder
        self.logger = logger
    }

    public func log(_ logEntry: LogEntry) {
        logger(logEntry.header.level.osLogType, self.logEntryEncoder.encode(logEntry, verbose: false))
    }
}
