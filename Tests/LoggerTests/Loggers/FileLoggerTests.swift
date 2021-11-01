//
//  FileLoggerTests.swift
//  
//
//  Created by Martin Troup on 30.09.2021.
//

@testable import Logger
import XCTest

class FileLoggerTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var fileManager: FileManager!
    private var fileLoggerManager: FileLoggerManager!

    override func setUp() {
        super.setUp()

        userDefaults = UserDefaults(suiteName: "testUserDefaults")!
        fileManager = FileManager.default
        fileLoggerManager = try! FileLoggerManager(
            fileManager: fileManager,
            userDefaults: userDefaults,
            dateFormatter: FileLogger.dateFormatter,
            numberOfLogFiles: 3
        )
    }

    override func tearDown() {
        try! FileManager.default.removeItem(atPath: fileLoggerManager.logDirURL.path)
        fileLoggerManager = nil

        userDefaults.removePersistentDomain(forName: "testUserDefaults")
        userDefaults = nil

        fileManager = nil

        super.tearDown()
    }

    func test_inicialization_of_FileLogger() {
        XCTAssertTrue(fileManager.directoryExists(at: fileLoggerManager.logDirURL))
        XCTAssertEqual(try! fileManager.numberOfFiles(inDirectory: fileLoggerManager.logDirURL), 0)

        let currentLogFileNumber = userDefaults.object(forKey: Constants.UserDefaultsKeys.currentLogFileNumber) as? Int
        XCTAssertEqual(currentLogFileNumber, 0)

        let dateOfLastLog = userDefaults.object(forKey: Constants.UserDefaultsKeys.dateOfLastLog) as? Date
        XCTAssertNotNil(dateOfLastLog)

        let numberOfLogFiles = userDefaults.object(forKey: Constants.UserDefaultsKeys.numberOfLogFiles) as? Int
        XCTAssertEqual(numberOfLogFiles, 3)
    }

    func test_archive_availability() {
        let fileLogger = FileLogger(fileLoggerManager: fileLoggerManager)

        fileLogger.log("Error message", onLevel: .error)
        fileLogger.log("Warning message", onLevel: .warn)

        // Archived log files check
        let archiveUrl = fileLogger.getArchivedLogFilesUrl()
        XCTAssertNotNil(archiveUrl)
        XCTAssertTrue(try! archiveUrl!.checkResourceIsReachable())
        try! FileManager.default.removeItem(at: archiveUrl!)
    }

    func test_file_rotation() {
        let fileLogger = FileLogger(fileLoggerManager: fileLoggerManager)

        // Day 1 == File 0
        fileLogger.log("Warning message", onLevel: .warn)

        XCTAssertEqual(fileLoggerManager.currentLogFileNumber, 0)
        XCTAssertEqual(
            fileLoggerManager.currentLogFileUrl,
            fileLoggerManager.logDirURL.appendingPathComponent("0").appendingPathExtension("log")
        )

        // Day 2 == File 1
        fileLoggerManager.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLoggerManager.dateOfLastLog)!

        fileLogger.log("Warning message", onLevel: .warn)

        XCTAssertEqual(fileLoggerManager.currentLogFileNumber, 1)
        XCTAssertEqual(
            fileLoggerManager.currentLogFileUrl,
            fileLoggerManager.logDirURL.appendingPathComponent("1").appendingPathExtension("log")
        )

        // Day 3 == File 2
        fileLoggerManager.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLoggerManager.dateOfLastLog)!

        fileLogger.log("Warning message", onLevel: .warn)

        XCTAssertEqual(fileLoggerManager.currentLogFileNumber, 2)
        XCTAssertEqual(
            fileLoggerManager.currentLogFileUrl,
            fileLoggerManager.logDirURL.appendingPathComponent("2").appendingPathExtension("log")
        )

       // Day 4 == File 0
        fileLoggerManager.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLoggerManager.dateOfLastLog)!

        fileLogger.log("Warning message", onLevel: .warn)

        XCTAssertEqual(fileLoggerManager.currentLogFileNumber, 0)
        XCTAssertEqual(
            fileLoggerManager.currentLogFileUrl,
            fileLoggerManager.logDirURL.appendingPathComponent("0").appendingPathExtension("log")
        )

        XCTAssertEqual(try! fileManager.numberOfFiles(inDirectory: fileLoggerManager.logDirURL), 3)
    }

    func test_single_logging_file() {
        let fileLogger = FileLogger(fileLoggerManager: fileLoggerManager)
        fileLogger.levels = [.error, .warn]

        fileLogger.log("Error message", onLevel: .error)

        fileLogger.log("Warning message\nThis is test!", onLevel: .warn)

        let fileLogs = try! fileLoggerManager.gettingRecordsFromLogFile(at: fileLoggerManager.currentLogFileUrl)

        XCTAssertEqual(2, fileLogs.count)

        XCTAssertNotNil(fileLogs[0].header)
        XCTAssertEqual(fileLogs[0].body, "Error message")

        XCTAssertNotNil(fileLogs[1].header)
        XCTAssertEqual(fileLogs[1].body, "Warning message\nThis is test!")
    }

    func test_pattern_match() {
        let string = "[WARNING \(DateFormatter.dateFormatter.string(from: Date()))]"

        let messageHeader = LogHeader.init(rawValue: string, dateFormatter: DateFormatter.dateFormatter)
        XCTAssertNotNil(messageHeader)
    }
}

// MARK: - FileManager + helper functions

private extension FileManager {
    func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDirectory)
    }

    func numberOfFiles(inDirectory url: URL) throws -> Int {
        try contentsOfDirectory(atPath: url.path).count
    }
}
