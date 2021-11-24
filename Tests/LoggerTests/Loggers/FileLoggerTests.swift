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

        fileLogger.log(.mock("Error message"))
        fileLogger.log(.mock("Warning message"))

        // Archived log files check
        let archiveUrl = fileLogger.getArchivedLogFilesUrl()
        XCTAssertNotNil(archiveUrl)
        XCTAssertTrue(try! archiveUrl!.checkResourceIsReachable())
        try! FileManager.default.removeItem(at: archiveUrl!)
    }

    func test_file_rotation() {
        let fileLogger = FileLogger(fileLoggerManager: fileLoggerManager)

        // Day 1 == File 0
        fileLogger.log(.mock("Warning message"))

        XCTAssertEqual(fileLoggerManager.currentLogFileNumber, 0)
        XCTAssertEqual(
            fileLoggerManager.currentLogFileUrl,
            fileLoggerManager.logDirURL.appendingPathComponent("0").appendingPathExtension("log")
        )

        // Day 2 == File 1
        fileLoggerManager.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLoggerManager.dateOfLastLog)!

        fileLogger.log(.mock("Warning message"))

        XCTAssertEqual(fileLoggerManager.currentLogFileNumber, 1)
        XCTAssertEqual(
            fileLoggerManager.currentLogFileUrl,
            fileLoggerManager.logDirURL.appendingPathComponent("1").appendingPathExtension("log")
        )

        // Day 3 == File 2
        fileLoggerManager.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLoggerManager.dateOfLastLog)!

        fileLogger.log(.mock("Warning message"))

        XCTAssertEqual(fileLoggerManager.currentLogFileNumber, 2)
        XCTAssertEqual(
            fileLoggerManager.currentLogFileUrl,
            fileLoggerManager.logDirURL.appendingPathComponent("2").appendingPathExtension("log")
        )

       // Day 4 == File 0
        fileLoggerManager.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLoggerManager.dateOfLastLog)!

        fileLogger.log(.mock("Warning message"))

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

        fileLogger.log(
            .init(
                header: .init(date: Date(), level: .info, dateFormatter: DateFormatter.monthsDaysTimeFormatter),
                location: .init(fileName: "file", function: "function", line: 1),
                message: "Error message"
            )
        )

        fileLogger.log(
            .init(
                header: .init(date: Date(), level: .info, dateFormatter: DateFormatter.monthsDaysTimeFormatter),
                location: .init(fileName: "file2", function: "function2", line: 20),
                message: "Warning message\nThis is test!"
            )
        )

        let fileLogs = try! fileLoggerManager.gettingRecordsFromLogFile(at: fileLoggerManager.currentLogFileUrl)

        XCTAssertEqual(fileLogs.count, 2)

        XCTAssertNotNil(fileLogs[0].header)
        XCTAssertEqual(fileLogs[0].body, "file - function - line 1: Error message")

        XCTAssertNotNil(fileLogs[1].header)
        XCTAssertEqual(fileLogs[1].body, "file2 - function2 - line 20: Warning message\nThis is test!")
    }

    func test_pattern_match() {
        let string = "[WARNING \(DateFormatter.dateFormatter.string(from: Date()))]"

        let messageHeader = LogHeader.init(rawValue: string, dateFormatter: DateFormatter.dateFormatter)
        XCTAssertNotNil(messageHeader)
    }


    func test_date_formatting() {
        let fileLogger = FileLogger(fileLoggerManager: fileLoggerManager)
        fileLogger.levels = [.error, .warn]

        let date = Date()

        XCTAssertEqual(Date(), Date())

        fileLogger.log(
            .init(
                header: .init(date: date, level: .info, dateFormatter: DateFormatter.dateTimeFormatter),
                location: .init(fileName: "file", function: "function", line: 1),
                message: "Error message"
            )
        )

        let fileLogs = try! fileLoggerManager.gettingRecordsFromLogFile(at: fileLoggerManager.currentLogFileUrl)

        XCTAssertEqual(fileLogs.count, 1)
        XCTAssertTrue(abs(date.timeIntervalSinceReferenceDate) - abs(fileLogs[0].header.date.timeIntervalSinceReferenceDate) < 0.001)
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
