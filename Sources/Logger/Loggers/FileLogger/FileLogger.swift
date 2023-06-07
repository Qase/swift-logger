//
//  FileLogger.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation

// MARK: - FileLoggerError

enum FileLoggerError: Error {
    case missingWritableFileHandle
    case stringToDataConversionFailure
    case userDefaultsInitFailure
}

// MARK: - SharingConfiguration

public enum SharingConfiguration {
    // Sharing resources between the application and its extension.
    // The user is required to set an App Group with assigned identifier.
    // All shared resources (UserDefaults and FileManager) are then available for all applications within the group.
    case shared(appGroupID: String, maxNumberOfFiles: Int, appName: String)
    // Resources are not shared between the application and its extension. UserDefaults.standard instance is used.
    case nonShared(maxNumberOfFiles: Int)
}

public extension SharingConfiguration {
    static func shared(appGroupID: String, appName: String) -> Self {
        SharingConfiguration.shared(appGroupID: appGroupID, maxNumberOfFiles: 4, appName: appName)
    }

    static var nonShared: Self {
        SharingConfiguration.nonShared(maxNumberOfFiles: 4)
    }
}

// MARK: - FileAccessExecutor

struct FileAccessExecutor {
    var execute: (@escaping () -> Void) -> ()
}

extension FileAccessExecutor {
    static func live(queue: DispatchQueue) -> Self {
        .init(execute: { queue.async(execute: $0) })
    }
}

extension FileAccessExecutor {
    static var syncMock: Self {
        .init { $0() }
    }
}

// MARK: - FileLogger

public class FileLogger: Logging {
    // MARK: - Stored properties

    private let logFilePathExtension: String = "log"
    private let appName: String?
    private let fileManager: FileManager
    private let userDefaults: UserDefaults
    private let logDirURL: URL
    private let namespace: String?
    private let numberOfLogFiles: Int
    private let dateFormatter: DateFormatter
    private let fileHeaderContent: String
    private let lineSeparator: String
    private let logEntryEncoder: LogEntryEncoding
    private let logEntryDecoder: LogEntryDecoding
    private let externalLogger: (String) -> ()
    private let fileAccessQueue: FileAccessExecutor

    var dateOfLastLog: Date {
        didSet {
            userDefaults.set(dateOfLastLog, forKey: String(Constants.UserDefaultsKeys.dateOfLastLog, prefixedBy: namespace))
        }
    }

    var currentLogFileNumber: Int {
        didSet {
            userDefaults.set(currentLogFileNumber, forKey: String(Constants.UserDefaultsKeys.currentLogFileNumber, prefixedBy: namespace))
        }
    }
    
    private var currentWritableFileHandle: FileHandle? {
        willSet {
            if currentWritableFileHandle != newValue {
                currentWritableFileHandle?.closeFile()
            }
        }
    }

    var currentLogFileUrl: URL {
        logDirURL
            .appendingPathComponent(String(currentLogFileNumber, prefixedBy: appName))
            .appendingPathExtension(logFilePathExtension)
    }

    public var levels: [Level] = [.info]

    // MARK: - Initializers

    /// This is public constructor for FileLogger.
    /// - Parameters:
    ///   - sharingConfiguration: Enables to setup possible source sharing between the application and its extensions.
    ///   - namespace: A namespace dedicated to a single instance of `FileLogger`. Used to name the directory with files and for prefixing `UserDefaults` keys.
    ///   - fileHeaderContent: Custom header content of each logging file.
    ///   - lineSeparator: Separation style applied between individual log entries.
    ///   - logEntryEncoder: Custom log entry encoder.
    ///   - logEntryDecoder: Custom log entry decoder.
    ///   - loggerForInternalErrors: Logging possibility for error handling happening within the logger.
    public convenience init(
        sharingConfiguration: SharingConfiguration = .nonShared,
        namespace: String = "logs",
        fileHeaderContent: String = "",
        lineSeparator: String = "\u{2028}",
        logEntryEncoder: LogEntryEncoding = LogEntryEncoder(),
        logEntryDecoder: LogEntryDecoding = LogEntryDecoder(),
        loggerForInternalErrors: @escaping (String) -> () = { print($0) }
    ) throws {
        let fileManager = FileManager.default

        switch sharingConfiguration {
        case let .nonShared(maxNumOfFiles):
            try self.init(
                appName: nil,
                fileManager: fileManager,
                userDefaults: .standard,
                logDirURL: fileManager.documentDirectoryURL(withName: namespace),
                namespace: namespace,
                numberOfLogFiles: maxNumOfFiles,
                fileHeaderContent: fileHeaderContent,
                lineSeparator: lineSeparator,
                logEntryEncoder: logEntryEncoder,
                logEntryDecoder: logEntryDecoder,
                externalLogger: loggerForInternalErrors
            )

        case let .shared(appGroupID, maxNumberOfFiles, appName):
            guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
                throw FileLoggerError.userDefaultsInitFailure
            }

            try self.init(
                appName: appName,
                fileManager: fileManager,
                userDefaults: userDefaults,
                logDirURL: fileManager.documentDirectoryURL(withName: namespace, usingAppGroupID: appGroupID),
                namespace: namespace,
                numberOfLogFiles: maxNumberOfFiles,
                fileHeaderContent: fileHeaderContent,
                lineSeparator: lineSeparator,
                logEntryEncoder: logEntryEncoder,
                logEntryDecoder: logEntryDecoder,
                externalLogger: loggerForInternalErrors
            )
        }
    }

    init(
        appName: String?,
        fileManager: FileManager,
        userDefaults: UserDefaults,
        logDirURL: URL,
        namespace: String?,
        numberOfLogFiles: Int,
        dateFormatter: DateFormatter = .monthsDaysTimeFormatter,
        fileHeaderContent: String,
        lineSeparator: String,
        logEntryEncoder: LogEntryEncoding,
        logEntryDecoder: LogEntryDecoding,
        externalLogger: @escaping (String) -> (),
        fileAccessQueue: FileAccessExecutor = .live(queue: .defaultSerialFileManagerQueue)
    ) throws {
        self.appName = appName
        self.fileManager = fileManager
        self.userDefaults = userDefaults
        self.logDirURL = logDirURL
        self.namespace = namespace
        self.numberOfLogFiles = numberOfLogFiles
        self.dateFormatter = dateFormatter
        self.fileHeaderContent = fileHeaderContent
        self.lineSeparator = lineSeparator
        self.logEntryEncoder = logEntryEncoder
        self.logEntryDecoder = logEntryDecoder
        self.externalLogger = externalLogger
        self.fileAccessQueue = fileAccessQueue

        // Create log directory
        try fileManager.createDirectoryIfNotExists(at: logDirURL)

        // If the number of logFiles got decreased -> delete all existing log files.
        // Otherwise, there would be unused files in the log directory.
        // It is important to notice that when changing numOfLogFiles parameter some logs might be lost!
        if numberOfLogFiles < userDefaults.integer(forKey: String(Constants.UserDefaultsKeys.numberOfLogFiles, prefixedBy: namespace)) {
            try fileManager.deleteAllFiles(at: logDirURL, withPathExtension: logFilePathExtension)
        }

        userDefaults.set(self.numberOfLogFiles, forKey: String(Constants.UserDefaultsKeys.numberOfLogFiles, prefixedBy: namespace))

        self.dateOfLastLog = userDefaults.object(
            forKey: String(Constants.UserDefaultsKeys.dateOfLastLog, prefixedBy: namespace)
        ) as? Date ?? Date()
        userDefaults.set(self.dateOfLastLog, forKey: String(Constants.UserDefaultsKeys.dateOfLastLog, prefixedBy: namespace))

        self.currentLogFileNumber = userDefaults.integer(
            forKey: String(Constants.UserDefaultsKeys.currentLogFileNumber, prefixedBy: namespace)
        )
        userDefaults.set(self.currentLogFileNumber, forKey: String(Constants.UserDefaultsKeys.currentLogFileNumber, prefixedBy: namespace))
    }

    // MARK: - Computed properties & methods

    public func logRecords(filteredBy filter: (LogEntry) -> Bool = { _ in true }) -> [LogEntry]? {
        perFileLogRecords(filteredBy: filter)?.flatMap(\.value)
    }

    func perFileLogRecords(filteredBy filter: (LogEntry) -> Bool = { _ in true }) -> [URL: [LogEntry]]? {
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
            return try fileManager.allFiles(at: logDirURL, withPathExtension: logFilePathExtension)
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

    public func deleteAllLogFiles() throws {
        fileAccessQueue.execute {
            do {
                try self.fileManager.deleteAllFiles(at: self.logDirURL, withPathExtension: self.logFilePathExtension)
                self.currentWritableFileHandle = nil
                self.currentLogFileNumber = 0
            } catch {
                self.externalLogger("Failed to delete all log files with error: \(error)!")
            }
        }
    }

    public var logFiles: [URL] {
        get throws {
            try fileManager.allFiles(at: logDirURL, withPathExtension: logFilePathExtension)
        }
    }

    /// Method to write a log message into the current log file.
    ///
    /// - Parameters:
    ///   - log: `LogEntry` instance with header, location and log message
    public func log(_ logEntry: LogEntry) {
        let unwrapped: (FileHandle?) throws -> FileHandle = { fileHandle in
            guard let fileHandle = fileHandle else { throw FileLoggerError.missingWritableFileHandle }

            return fileHandle
        }

        let utf8Data: (String) throws -> Data = { string in
            guard let data = string.data(using: .utf8) else { throw FileLoggerError.stringToDataConversionFailure }

            return data
        }
        
        fileAccessQueue.execute {
            do {
                try self.refreshCurrentLogFileStatus()
                
                let contentToAppend = self.logEntryEncoder.encode(logEntry) + self.lineSeparator
                let fileHandle = try unwrapped(self.currentWritableFileHandle)
                
                fileHandle.seekToEndOfFile()
                fileHandle.write(try utf8Data(contentToAppend))
            } catch let error {
                self.externalLogger("Failed to write to a log file with error: \(error)!")
            }
        }
    }

    /// Method to refresh / set `currentLogFileNumber`, `dateOfLastLog` & `currentWritableFileHandle` properties.
    /// It is called at the beginning of `writeToLogFile(_, _)` method.
    private func refreshCurrentLogFileStatus() throws {
        let fileHandle: (FileManager, URL) throws -> FileHandle = { fileManager, url in
            try fileManager.createFileIfNotExists(at: url, withInitialContent: self.fileHeaderContent)

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
        try fileManager.deleteFileIfExists(at: currentLogFileUrl)
        currentWritableFileHandle = try fileHandle(fileManager, currentLogFileUrl)
    }

    /// Method that parses a log file content into an array of LogFileRecord instances
    ///
    /// - Parameter fileUrlToRead: fileName of a log file to parse
    /// - Returns: array of LogFileRecord instances
    func gettingRecordsFromLogFile(at fileUrlToRead: URL) throws -> [LogEntry] {
        try fileManager.contents(fromFileIfExists: fileUrlToRead)
            .components(separatedBy: lineSeparator)
            .compactMap(logEntryDecoder.decode)
    }
}

// MARK: - String + prefixedBy

private extension String {
    init<Value: CustomStringConvertible, Prefix: CustomStringConvertible>(_ value: Value, prefixedBy prefix: Prefix?) {
        self = "\(prefix.map { "\(String(describing: $0))-" } ?? "")\(String(describing: value))"
    }
}

// MARK: - DispatchQueue + default fileManager queue

private extension DispatchQueue {
    static let defaultSerialFileManagerQueue = DispatchQueue(label: Constants.Queues.serial, qos: .background)
}
