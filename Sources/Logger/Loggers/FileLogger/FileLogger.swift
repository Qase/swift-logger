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

    /// FileLogger initialization
    ///
    /// - Parameters:
    ///   - userDefaults: `UserDefaults` storage instance, where necessary metadata for the logger are stored.
    ///   Use different `UserDefaults.init(suiteName:)` when registering multiple instances of `FileLogger`.
    ///   - fileManager: `FileManager` instance used for persisting logging files
    ///   - suiteName: name of the application. Must be used if logs are to be shared between the app and its extensions.
    ///   - logDirectoryName: name of the directory, where logging files are to be stored
    ///   - fileHeaderContent: such `String` will be placed at the header of each logging file. Empty `String` is used as default.
    ///   - numberOfLogFiles: a number of log files that can be used for logging
    public init(
      userDefaults: UserDefaults = UserDefaults.standard,
      fileManager: FileManager = FileManager.default,
      suiteName: String? = nil,
      logDirectoryName: String = "logs",
      fileHeaderContent: String = "",
      numberOfLogFiles: Int = 4
    ) throws {
        fileLoggerManager = try FileLoggerManager(
          fileManager: fileManager,
          userDefaults: userDefaults,
          dateFormatter: DateFormatter.monthsDaysTimeFormatter,
          externalLogger: { print($0) },
          suiteName: suiteName,
          logDirectoryName: logDirectoryName,
          fileHeaderContent: fileHeaderContent,
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
