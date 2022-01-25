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
    private let fileLoggerManager = FileLoggerManager.shared

    /// Property to set a number of log files that can be used for loging.
    public var numOfLogFiles: Int = 4 {
        didSet {
            fileLoggerManager.numOfLogFiles = numOfLogFiles
        }
    }

    public var archivedLogFilesSize: Int? {
        fileLoggerManager.archivedLogFilesSize
    }

    public var archivedLogFilesUrl: URL? {
        fileLoggerManager.archivedLogFilesUrl
    }

//    public var archivedLogFiles: Archive? {
//        fileLoggerManager.archivedLogFiles
//    }
    
    public var logFilesUrl: [URL]? {
        fileLoggerManager.gettingAllLogFiles()
    }

    public var levels: [Level] = [.info]

    public init() {}

    public var logFilesRecords: [LogFileRecord] {
        fileLoggerManager.logFilesRecords
    }

    public func log(_ message: String, onLevel level: Level) {
        fileLoggerManager.writeToLogFile(message: message, withMessageHeader: messageHeader(forLevel: level), onLevel: level)
    }

    public func deleteAllLogFiles() {
        fileLoggerManager.deleteAllLogFiles()
    }
}
