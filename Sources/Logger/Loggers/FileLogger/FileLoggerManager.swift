//
//  FileLoggerManager.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation
import Zip

enum FileLoggerManagerError: Error {
    case missingWritableFileHandle
    case stringToDataConversionFailure
}

/// LogFileManager manages all necessary operations for FileLogger.
class FileLoggerManager {

    // MARK: - Stored properties

    private let logFilePathExtension: String = "log"

    private let fileManager: FileManager
    private let userDefaults: UserDefaults
    private let suiteName: String?
    private let dateFormatter: DateFormatter
    let logDirURL: URL
    private let externalLogger: (String) -> ()

    var dateOfLastLog: Date {
        didSet {
            userDefaults.set(dateOfLastLog, forKey: Constants.UserDefaultsKeys.dateOfLastLog)
        }
    }

    var currentLogFileNumber: Int {
        didSet {
            userDefaults.set(currentLogFileNumber, forKey: Constants.UserDefaultsKeys.currentLogFileNumber)
        }
    }

    private let numberOfLogFiles: Int

    private var currentWritableFileHandle: FileHandle? {
        willSet {
            if currentWritableFileHandle != newValue {
                currentWritableFileHandle?.closeFile()
            }
        }
    }

    // MARK: - Initializers

    init(
        fileManager: FileManager = FileManager.default,
        userDefaults: UserDefaults = UserDefaults.standard,
        dateFormatter: DateFormatter,
        externalLogger: @escaping (String) -> () = { print($0) },
        suiteName: String? = nil,
        numberOfLogFiles: Int = 4
    ) throws {
        self.fileManager = fileManager
        self.userDefaults = userDefaults
        self.dateFormatter = dateFormatter
        self.externalLogger = externalLogger
        self.suiteName = suiteName
        self.logDirURL = try fileManager.documentDirectoryURL(withName: "logs", usingSuiteName: logFilePathExtension)

        try fileManager.createDirectoryIfNotExists(at: logDirURL)

        if numberOfLogFiles < userDefaults.integer(forKey: Constants.UserDefaultsKeys.numberOfLogFiles) {
            try fileManager.deleteAllFiles(at: logDirURL, withPathExtension: logFilePathExtension)
        }

        self.numberOfLogFiles = numberOfLogFiles
        userDefaults.set(numberOfLogFiles, forKey: Constants.UserDefaultsKeys.numberOfLogFiles)

        self.dateOfLastLog = userDefaults.object(forKey: Constants.UserDefaultsKeys.dateOfLastLog) as? Date ?? Date()
        userDefaults.set(self.dateOfLastLog, forKey: Constants.UserDefaultsKeys.dateOfLastLog)

        self.currentLogFileNumber = userDefaults.integer(forKey: Constants.UserDefaultsKeys.currentLogFileNumber)
        userDefaults.set(self.currentLogFileNumber, forKey: Constants.UserDefaultsKeys.currentLogFileNumber)
    }

    // MARK: - Computed properties & methods

    func perFileLogRecords(filteredBy filter: (FileLogEntry) -> Bool = { _ in true }) -> [URL: [FileLogEntry]]? {
        perFileLogs(gettingRecordsFromLogFile(at:))
            .map { perFileLogRecords in
                perFileLogRecords.mapValues { $0.filter(filter) }
            }
    }

    var perFileLogData: [URL: Data]? {
        perFileLogs(fileManager.contents(fromFileIfExists:))?.compactMapValues { $0.data(using: .utf8) }
    }

    private func perFileLogs<LogFormat>(_ logGetter: (URL) throws -> LogFormat) -> [URL: LogFormat]? {
        do {
            return try fileManager.allFiles(at: logDirURL, usingSuiteName: suiteName, withPathExtension: logFilePathExtension)
                .reduce([URL: LogFormat]()) { result, nextFile in
                    var newResult = result
                    newResult[nextFile] = try logGetter(nextFile)

                    return newResult
                }
        } catch let error {
            externalLogger("Failed to retrieve an array of LogFileRecord with error: \(error).")
            return nil
        }
    }

    var currentLogFileUrl: URL {
        suiteName == nil ?
            logDirURL.appendingPathComponent("\(currentLogFileNumber)").appendingPathExtension(logFilePathExtension) :
            logDirURL.appendingPathComponent("extension-\(currentLogFileNumber)").appendingPathExtension(logFilePathExtension)
    }

    func deleteAllLogFiles() throws {
        try fileManager.deleteAllFiles(at: logDirURL, usingSuiteName: suiteName, withPathExtension: logFilePathExtension)
    }

    func archiveWithLogFiles(withFileName archiveFileName: String? = nil) throws -> URL? {
        let logFiles = try fileManager.allFiles(at: logDirURL, withPathExtension: logFilePathExtension)

        return try Zip.quickZipFiles(logFiles, fileName: archiveFileName ?? "log_files_archive.zip")
    }

    /// Method to write a log message into the current log file.
    ///
    /// - Parameters:
    ///   - log: `LogEntry` instance with header, location and log message
    func writeToLogFile(logEntry: LogEntry) {
        let unwrapped: (FileHandle?) throws -> FileHandle = { fileHandle in
            guard let fileHandle = fileHandle else { throw FileLoggerManagerError.missingWritableFileHandle }

            return fileHandle
        }

        let utf8Data: (String) throws -> Data = { string in
            guard let data = string.data(using: .utf8) else { throw FileLoggerManagerError.stringToDataConversionFailure }

            return data
        }

        do {
            try refreshCurrentLogFileStatus()

            let contentToAppend = "\(Constants.FileLogger.logFileRecordSeparator) \(logEntry)\n"

            let fileHandle = try unwrapped(currentWritableFileHandle)
            fileHandle.seekToEndOfFile()
            fileHandle.write(try utf8Data(contentToAppend))
        } catch let error {
            externalLogger("Failed to write to a log file with error: \(error)!")
        }
    }

    /// Method to refresh / set `currentLogFileNumber`, `dateOfLastLog` & `currentWritableFileHandle` properties.
    /// It is called at the beginning of `writeToLogFile(_, _)` method.
    private func refreshCurrentLogFileStatus() throws {
        let fileHandle: (FileManager, URL) throws -> FileHandle = { fileManager, url in
            try fileManager.createFileIfNotExists(at: url, shouldRemoveExistingFileContents: true)
            return try FileHandle(forWritingTo: url)
        }

        let dateString = DateFormatter.dateFormatter.string(from:)

        let currentDate = Date()

        let isSameDay = dateString(currentDate) == dateString(dateOfLastLog)

        if isSameDay, currentWritableFileHandle == nil {
            currentWritableFileHandle = try fileHandle(fileManager, currentLogFileUrl)

            return
        }

        if isSameDay { return }

        currentLogFileNumber = (currentLogFileNumber + 1) % numberOfLogFiles
        dateOfLastLog = currentDate
        currentWritableFileHandle = try fileHandle(fileManager, currentLogFileUrl)
    }

    /// Method that parses a log file content into an array of LogFileRecord instances
    ///
    /// - Parameter fileUrlToRead: fileName of a log file to parse
    /// - Returns: array of LogFileRecord instances
    func gettingRecordsFromLogFile(at fileUrlToRead: URL) throws -> [FileLogEntry] {
        try fileManager.contents(fromFileIfExists: fileUrlToRead)
            .components(separatedBy: Constants.FileLogger.logFileRecordSeparator)
            .dropFirst()
            .map { FileLogEntry(rawValue: $0, dateFormatter: dateFormatter) }
            .compactMap { $0 }
    }
}

