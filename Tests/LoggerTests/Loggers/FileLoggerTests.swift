//
//  FileLoggerTests.swift
//  
//
//  Created by Martin Troup on 30.09.2021.
//

@testable import Logger
import XCTest

class FileLoggerTests: XCTestCase {

    override func setUp() {
        super.setUp()

        LogManager.shared.removeAllLoggers()
    }

    func test_inicialization_of_FileLogger() {
        // Set default values for all Logger properties and store them to UserDefaults
        let fileLoggerManager = FileLoggerManager.shared
        fileLoggerManager.resetPropertiesToDefaultValues()

        if let _currentLogFileNumber = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.currentLogFileNumber) as? Int {
            XCTAssertEqual(0, _currentLogFileNumber)
        } else {
            XCTFail()
        }

        if let _dateTimeOfLastLog = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.dateOfLastLog) as? Date {
            XCTAssertNotNil(_dateTimeOfLastLog.toFullDateString().range(of: "^\\d{4}-\\d{2}-\\d{2}$", options: .regularExpression))
        } else {
            XCTFail()
        }

        if let _numOfLogFiles = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.numOfLogFiles) as? Int {
            XCTAssertEqual(4, _numOfLogFiles)
        } else {
            XCTFail()
        }
    }

    func test_FileLogger() {
        let fileLoggerManager = FileLoggerManager.shared
        fileLoggerManager.resetPropertiesToDefaultValues()

        guard fileLoggerManager.logDirUrl != nil, let _currentLogFileUrl = fileLoggerManager.currentLogFileUrl else {
            XCTFail("Failed to set log directory or current log file")
            return
        }

        // Set Console logger and File logger
        let logManager = LogManager.shared
        logManager.removeAllLoggers()

        let consoleLogger = ConsoleLogger()
        consoleLogger.levels = [.warn, .error]
        _ = logManager.add(consoleLogger)

        let fileLogger = FileLogger()
        fileLogger.levels = [.error, .info]
        _ = logManager.add(fileLogger)

        // Should be displayed in console + written to file
        Log("Error message", onLevel: .error)
        // Should be displayed in console + NOT written to file
        Log("Warning message", onLevel: .warn)
        // Should NOT be displayed in console + written to file
        Log("Info message", onLevel: .info)

        logManager.waitForLogingJobsToFinish()

        // Archived log files check
        let archiveUrl = fileLogger.archivedLogFilesUrl
        XCTAssertNotNil(archiveUrl)
        do {
            let reachable = try archiveUrl!.checkResourceIsReachable()
            XCTAssertTrue(reachable)
        } catch {
            XCTFail("Archive with log files was not created.")
        }

        // Delete archive
        do {
            try FileManager.default.removeItem(at: archiveUrl!)
        } catch {
            XCTFail("Failed to remove created archive.")
        }

        // Check if logs were correctly written in the log file
        let contentOfLogFile = fileLoggerManager.readingContentFromLogFile(at: _currentLogFileUrl)

        guard let _contentOfLogFile = contentOfLogFile else {
            XCTFail("Log file is empty even though it should not be!")
            return
        }

        let linesOfContent = _contentOfLogFile.components(separatedBy: .newlines)

        XCTAssertNotNil(linesOfContent[0].range(of: "^\\[.*] \\[ERROR \\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}] .* - .* - line \\d+: Error message$", options: .regularExpression))
        XCTAssertNotNil(linesOfContent[1].range(of: "^\\[.*] \\[INFO \\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}] .* - .* - line \\d+: Info message$", options: .regularExpression))

        // Delete the log file
        fileLoggerManager.deleteLogFile(at: _currentLogFileUrl)
    }

    func test_parsing_of_log_file() {
        let fileLoggerManager = FileLoggerManager.shared
        fileLoggerManager.resetPropertiesToDefaultValues()

        guard fileLoggerManager.logDirUrl != nil, let _currentLogFileUrl = fileLoggerManager.currentLogFileUrl else {
            XCTFail("Failed to set log directory or current log file")
            return
        }

        // Set Console logger and File logger
        let logManager = LogManager.shared
        logManager.removeAllLoggers()

        let fileLogger = FileLogger()
        fileLogger.levels = [.error, .warn]
        _ = logManager.add(fileLogger)

        Log("Error message", onLevel: .error)
        Log("Warning message\nThis is test!", onLevel: .warn)

        logManager.waitForLogingJobsToFinish()

        let logFileRecords = fileLoggerManager.gettingRecordsFromLogFile(at: _currentLogFileUrl)

        guard let _logFileRecords = logFileRecords else {
            XCTFail("No log file records were parsed from the log file even though there should be 2 of them.")
            return
        }

        XCTAssertEqual(2, _logFileRecords.count)

        XCTAssertNotNil(_logFileRecords[0].header.range(of: "^\\[ERROR \\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}]$", options: .regularExpression))
        XCTAssertNotNil(_logFileRecords[0].body.range(of: "^.* - .* - line \\d+: Error message\n$", options: .regularExpression))

        XCTAssertNotNil(_logFileRecords[1].header.range(of: "^\\[WARNING \\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}]$", options: .regularExpression))
        XCTAssertNotNil(_logFileRecords[1].body.range(of: "^.* - .* - line \\d+: Warning message\nThis is test!\n$", options: .regularExpression))

        // Delete the log file
        fileLoggerManager.deleteLogFile(at: _currentLogFileUrl)
    }
}
