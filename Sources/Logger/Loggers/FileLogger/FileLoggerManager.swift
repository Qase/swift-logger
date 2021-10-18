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
        externalLogger: @escaping (String) -> () = { print($0) },
        suiteName: String? = nil,
        numberOfLogFiles: Int = 4
    ) throws {
        self.fileManager = fileManager
        self.userDefaults = userDefaults
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

    var perFileLogRecords: [URL: [LogFileRecord]]? {
        do {
            return try fileManager.allFiles(at: logDirURL, usingSuiteName: suiteName, withPathExtension: logFilePathExtension)
                .reduce([URL: [LogFileRecord]]()) { result, nextFile in
                    var newResult = result
                    newResult[nextFile] = try gettingRecordsFromLogFile(at: nextFile)

                    return newResult
                }
        } catch let error {
            externalLogger("Failed to retrieve an array of LogFileRecord with error: \(error).")
            return nil
        }
    }

    var perFileLogData: [URL: Data]? {
        do {
            return try fileManager.allFiles(at: logDirURL, usingSuiteName: suiteName, withPathExtension: logFilePathExtension)
                .reduce([URL: Data]()) { result, nextFile in
                    var newResult = result
                    newResult[nextFile] = try fileManager.contents(fromFileIfExists: nextFile).data(using: .utf8)

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
    ///   - message: String logging message
    ///   - withMessageHeader: Log message unified header
    ///   - onLevel: Level of the logging message
    func writeToLogFile(message: String, withMessageHeader messageHeader: String, onLevel level: Level) {
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

            let contentToAppend = "\(Constants.FileLogger.logFileRecordSeparator) \(messageHeader) \(message)\n"

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

        let currentDate = Date()

        if currentDate == dateOfLastLog, currentWritableFileHandle == nil {
            currentWritableFileHandle = try fileHandle(fileManager, currentLogFileUrl)

            return
        }

        if currentDate == dateOfLastLog { return }

        currentLogFileNumber = (currentLogFileNumber + 1) % numberOfLogFiles
        dateOfLastLog = currentDate
        currentWritableFileHandle = try fileHandle(fileManager, currentLogFileUrl)
    }

    /// Method that parses a log file content into an array of LogFileRecord instances
    ///
    /// - Parameter fileUrlToRead: fileName of a log file to parse
    /// - Returns: array of LogFileRecord instances
    func gettingRecordsFromLogFile(at fileUrlToRead: URL) throws -> [LogFileRecord] {
        try fileManager.contents(fromFileIfExists: fileUrlToRead)
            .components(separatedBy: Constants.FileLogger.logFileRecordSeparator)
            .dropFirst()
            .map(LogFileRecord.init(fromFileLogRecord:))
    }
}

// MARK: - LogFileRecord + parsing

private extension LogFileRecord {
    init(fromFileLogRecord fileLogRecord: String) {
        let headerTrimmed = fileLogRecord
            .prefix(while: { $0 != "]" })
            .dropFirst()

        let header = String(headerTrimmed) + "]"

        let body = fileLogRecord
            .suffix(from: headerTrimmed.endIndex)
            .dropFirst(2)

        self.header = header
        self.body = String(body)
    }
}

// MARK: - Date + Equatable

private extension Date {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.toFullDateString() == rhs.toFullDateString()
    }
}
