//
//  FileLoggerManager.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation
import Zip

/// LogFileManager manages all necessary operations for FileLogger.
class FileLoggerManager {

    // MARK: - Stored properties

    private let suiteName: String?

    private var dateOfLastLog: Date = Date() {
        didSet {
            UserDefaults.standard.set(dateOfLastLog, forKey: Constants.UserDefaultsKeys.dateOfLastLog)
        }
    }

    private(set) var currentLogFileNumber: Int = 0 {
        didSet {
            // Check if currentLogFileNumber got updated, if not - do nothing, thus keep the currentWritableFileHandle opened
            if oldValue == currentLogFileNumber {
                if currentWritableFileHandle == nil {
                    assignNewFileHandle()
                }
            }

            UserDefaults.standard.set(currentLogFileNumber, forKey: Constants.UserDefaultsKeys.currentLogFileNumber)

            // Check if new currentLogFileUrl is available (only a safety check, because its part - logDirUrl is Optional
            guard let currentLogFileUrl = currentLogFileUrl else {
                assertionFailure("New currentLogFileUrl not available while trying to open appropriate currentWritableFileHandler.")
                return
            }

            // Delete the file that is about to be used (it is overriden in a file cycle)
            deleteLogFile(at: currentLogFileUrl)

            // Open new fileHandle and assign it to currentWritableFileHandle
            assignNewFileHandle()
        }
    }

    var numOfLogFiles: Int = 4 {
        willSet(newNumOfLogFiles) {
            if newNumOfLogFiles == 0 {
                assertionFailure("There must be at least 1 log file so FileLogger can be used.")
            }

            if numOfLogFiles > newNumOfLogFiles {
                deleteAllLogFiles()
            }
        }
        didSet {
            UserDefaults.standard.set(numOfLogFiles, forKey: Constants.UserDefaultsKeys.numOfLogFiles)
        }
    }

    private var currentWritableFileHandle: FileHandle? {
        willSet {
            guard currentWritableFileHandle != newValue else { return }

            currentWritableFileHandle?.closeFile()
        }
    }

    lazy var logDirUrl: URL? = {
        do {
            let fileManager = FileManager.default

            let dirUrl: URL
            if let suiteName = suiteName, let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: suiteName) {
                dirUrl = url
            } else {
                dirUrl = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            }

            let logDirUrl = dirUrl.appendingPathComponent("logs")

            if !fileManager.fileExists(atPath: logDirUrl.path) {
                try fileManager.createDirectory(at: logDirUrl, withIntermediateDirectories: true, attributes: nil)
            }

            print("File log directory: \(logDirUrl).")

            return logDirUrl
        } catch let error {
            assertionFailure("Failed to create log directory within init() with error: \(error).")
            return nil
        }
    }()

    // MARK: - Initializers

    init(suiteName: String? = nil) {
        self.suiteName = suiteName

        if let dateOfLastLog = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.dateOfLastLog) as? Date {
            self.dateOfLastLog = dateOfLastLog
        } else {
            UserDefaults.standard.set(dateOfLastLog, forKey: Constants.UserDefaultsKeys.dateOfLastLog)
        }

        if let currentLogFileNumber = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.currentLogFileNumber) as? Int {
            self.currentLogFileNumber = currentLogFileNumber
        } else {
            UserDefaults.standard.set(currentLogFileNumber, forKey: Constants.UserDefaultsKeys.currentLogFileNumber)
        }

        if let numOfLogFiles = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.numOfLogFiles) as? Int {
            self.numOfLogFiles = numOfLogFiles
        } else {
            UserDefaults.standard.set(numOfLogFiles, forKey: Constants.UserDefaultsKeys.numOfLogFiles)
        }
    }

    // MARK: - Computed properties & functions

    var logFilesRecords: [LogFileRecord] {
        guard let logDirUrl = logDirUrl else { return [] }

        return (0..<numOfLogFiles).reduce(into: [LogFileRecord]()) { result, index in
            let logFileNumber = (currentLogFileNumber + index) % numOfLogFiles
            let logFileUrl = logDirUrl.appendingPathComponent("\(logFileNumber)").appendingPathExtension("log")

            guard let logFileRecords = gettingRecordsFromLogFile(at: logFileUrl) else { return }

            result.append(contentsOf: logFileRecords)
        }
    }

    var currentLogFileUrl: URL? {
        suiteName == nil ?
            logDirUrl?.appendingPathComponent("\(currentLogFileNumber)").appendingPathExtension("log") :
            logDirUrl?.appendingPathComponent("extension-\(currentLogFileNumber)").appendingPathExtension("log")
    }

    // Zip file size (in bytes)
    var archivedLogFilesSize: Int? {
        do {
            let resources = try getArchivedLogFilesUrl()?.resourceValues(forKeys: [.fileSizeKey])
            let fileSize = resources?.fileSize
            return fileSize
        } catch {
            return nil
        }
    }

    // Zip file containing log files
    func getArchivedLogFilesUrl(withFileName archiveFileName: String? = nil) -> URL? {
        // Get all log files to the archive
        guard let allLogFiles = gettingAllLogFiles(), !allLogFiles.isEmpty else {
            print("\(#function) - no log files.")
            return nil
        }

        do {
            return try Zip.quickZipFiles(allLogFiles, fileName: archiveFileName ?? "log_files_archive.zip")
        } catch let error {
            print("\(#function) - failed to zip log files with error: \(error).")
            return nil
        }
    }

    /// Method to reset properties that control the correct flow of storing log files.
    /// - "currentLogFileNumber" represents the current logging file number
    /// - "dateTimeOfLastLog" represents the last date the logger was used
    /// - "numOfLogFiles" represents the number of files that are used for logging, can be set by a user
    func resetPropertiesToDefaultValues() {
        currentWritableFileHandle = nil
        currentLogFileNumber = 0
        dateOfLastLog = Date()
        numOfLogFiles = 4
    }

    /// Method to remove all log files from dedicated log folder. These files are detected by its ".log" suffix.
    func deleteAllLogFiles() {
        guard let aLogFiles = gettingAllLogFiles() else { return }

        aLogFiles.forEach { aLogFileUrl in
            deleteLogFile(at: aLogFileUrl)
        }

        resetPropertiesToDefaultValues()
    }

    /// Method to delete a specific log file from dedicated log folder.
    ///
    /// - Parameter fileUrlToDelete: fileName of the log file to be removed
    func deleteLogFile(at fileUrlToDelete: URL) {
        if !FileManager.default.fileExists(atPath: fileUrlToDelete.path) { return }

        do {
            try FileManager.default.removeItem(at: fileUrlToDelete)
        } catch {
            assertionFailure("Failed to remove log file with error: \(error)")
        }
    }

    /// Method to create a specific log file from dedicated log folder.
    ///
    /// - Parameter fileUrlToAdd: fileName of the log file to be added
    private func createLogFile(at fileUrlToAdd: URL) {
        if FileManager.default.fileExists(atPath: fileUrlToAdd.path) { return }

        if !FileManager.default.createFile(atPath: fileUrlToAdd.path, contents: nil) {
            assertionFailure("Creating new log file failed.")
        }
    }

    /// Method to open a new file descriptor and assign it to currentWritableFileHandle
    ///
    /// - Parameter fileUrl: fileName of the log file to open file descriptor on
    private func assignNewFileHandle() {
        guard let currentLogFileUrl = currentLogFileUrl else {
            assertionFailure("Unavailable currentLogFileUrl while trying to assign new currentWritableFileHandle.")
            return
        }

        // Create the file that is about to be used and open its FileHandle (assign it to current WritableFileHandle) if not exists yet.
        createLogFile(at: currentLogFileUrl)

        // Open new file descriptor (FileHandle)
        do {
            currentWritableFileHandle = try FileHandle(forWritingTo: currentLogFileUrl)
        } catch let error {
            assertionFailure("Failed to get FileHandle instance (writable file descriptor) for currentLogFileUrl with error: \(error).")
        }
    }

    /// Method to get all log file names from dedicated log folder. These files are detected by its ".log" suffix.
    ///
    /// - Returns: Array of log file names
    func gettingAllLogFiles() -> [URL]? {
        let extensionDirectory = suiteName
            .flatMap { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0)?.appendingPathComponent("logs") }
            .flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil }

        let logDirectories = [logDirUrl] + [extensionDirectory]

        do {
            let directoryContent = try logDirectories
                .compactMap { $0 }
                .flatMap { try FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil, options: []) }

            let logFiles = directoryContent.filter({ file -> Bool in
                file.pathExtension == "log"
            })
            return logFiles
        } catch let error {
            assertionFailure("Failed to get log directory content with error: \(error).")
        }

        return nil
    }

    /// Method to write a log message into the current log file.
    ///
    /// - Parameters:
    ///   - message: String logging message
    ///   - withMessageHeader: Log message unified header
    ///   - onLevel: Level of the logging message
    func writeToLogFile(message: String, withMessageHeader messageHeader: String, onLevel level: Level) {
        guard logDirUrl != nil, currentLogFileUrl != nil else {
            assertionFailure("logDirUrl or currentLogFileUrl not available while trying to write a message (log) in it.")
            return
        }

        refreshCurrentLogFileStatus()

        let contentToAppend = "\(Constants.FileLogger.logFileRecordSeparator) \(messageHeader) \(message)\n"

        currentWritableFileHandle?.seekToEndOfFile()
        if let contentToAppend = contentToAppend.data(using: .utf8) {
            currentWritableFileHandle?.write(contentToAppend)
        }
    }

    /// Method to refresh/set "currentLogFileNumber" and "dateTimeOfLastLog" properties. It is called at the beginning
    /// of writeToLogFile(_, _) method.
    private func refreshCurrentLogFileStatus() {
        let currentDate = Date()
        if currentDate.toFullDateString() != dateOfLastLog.toFullDateString() {
            currentLogFileNumber = (currentLogFileNumber + 1) % numOfLogFiles
            dateOfLastLog = currentDate
        }

        if currentWritableFileHandle == nil {
            assignNewFileHandle()
        }
    }

    /// Method to get String content of a specific log file from dedicated log folder.
    ///
    /// - Parameter fileUrlToRead: fileName of the log file to be read from
    /// - Returns: content of the log file
    func readingContentFromLogFile(at fileUrlToRead: URL) -> String? {
        guard FileManager.default.fileExists(atPath: fileUrlToRead.path) else { return nil }

        do {
            return try String(contentsOf: fileUrlToRead, encoding: .utf8)
        } catch let error {
            assertionFailure("Failed to read \(fileUrlToRead.path) with error: \(error).")
        }

        return nil
    }

    /// Method that parses a log file content into an array of LogFileRecord instances
    ///
    /// - Parameter fileUrlToRead: fileName of a log file to parse
    /// - Returns: array of LogFileRecord instances
    func gettingRecordsFromLogFile(at fileUrlToRead: URL) -> [LogFileRecord]? {
        guard let logFileContent = readingContentFromLogFile(at: fileUrlToRead) else { return nil }

        var arrayOflogFileRecords = logFileContent.components(separatedBy: Constants.FileLogger.logFileRecordSeparator)

        arrayOflogFileRecords.remove(at: 0)
        let logFileRecords = arrayOflogFileRecords.map { logFileRecordInString -> LogFileRecord in

            let headerTrimmed = logFileRecordInString
                .prefix(while: { $0 != "]" })
                .dropFirst()

            let header = headerTrimmed.string + "]"

            let body = logFileRecordInString
                .suffix(from: headerTrimmed.endIndex)
                .dropFirst(2)
                .string

            return LogFileRecord(header: header, body: body)
        }

        return logFileRecords
    }
}

// MARK: - Substring + helpers

private extension Substring {
    var string: String {
        String(self)
    }
}
