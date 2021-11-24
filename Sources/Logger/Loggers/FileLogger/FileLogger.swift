//
//  FileLogger.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation
import Zip

/// Pre-built logger that logs to a single or multiple files within dedicated log dir.
public class FileLogger: Logging {
    private let fileLoggerManager: FileLoggerManager

    public func getArchivedLogFilesUrl(withFileName archiveFileName: String? = nil) -> URL? {
        try? fileLoggerManager.archiveWithLogFiles(withFileName: archiveFileName)
    }

    public var levels: [Level] = [.info]

    /// FileLogger initializer
    ///
    /// - Parameters:
    ///   - subsystem: suit name of the application. Must be passed to create logs from app extensions.
    ///   - numberOfLogFiles: a number of log files that can be used for logging
    public init(suiteName: String? = nil, numberOfLogFiles: Int = 4) throws {
        fileLoggerManager = try FileLoggerManager(
            suiteName: suiteName,
            numberOfLogFiles: numberOfLogFiles
        )
    }

    init(fileLoggerManager: FileLoggerManager) {
        self.fileLoggerManager = fileLoggerManager
    }

    public func logFilesRecords(filteredBy filter: (FileLogEntry) -> Bool = { _ in true }) -> [FileLogEntry]? {
        fileLoggerManager.perFileLogRecords(filteredBy: filter)?.flatMap(\.value)
    }

    var perFileLogData: [URL: Data]? {
        fileLoggerManager.perFileLogData
    }

    public func log(_ logEntry: LogEntry) {
        fileLoggerManager.writeToLogFile(logEntry: logEntry)
    }

    /// Delete all logs
    public func deleteAllLogFiles() throws {
        try? fileLoggerManager.deleteAllLogFiles()
    }
}
