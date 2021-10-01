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

    /// Property to set a number of log files that can be used for loging.
    public var numOfLogFiles: Int = 4 {
        didSet {
            fileLoggerManager.numOfLogFiles = numOfLogFiles
        }
    }

    public func getArchivedLogFilesUrl(withFileName archiveFileName: String? = nil) -> URL? {
        fileLoggerManager.getArchivedLogFilesUrl(withFileName: archiveFileName)
    }

    public var levels: [Level] = [.info]

    /// FileLogger initializer
    ///
    /// - Parameters:
    ///   - subsystem: suit name of the application. Must be passed to create logs from app extensions.
    public init(suiteName: String? = nil) {
        fileLoggerManager = FileLoggerManager(suiteName: suiteName)
    }

    public var logFilesRecords: [LogFileRecord] {
        fileLoggerManager.logFilesRecords
    }

    public func log(_ message: String, onLevel level: Level) {
        fileLoggerManager.writeToLogFile(message: message, withMessageHeader: messageHeader(forLevel: level), onLevel: level)
    }

    /// Delete all logs
    public func deleteAllLogFiles() {
        fileLoggerManager.deleteAllLogFiles()
    }
}
