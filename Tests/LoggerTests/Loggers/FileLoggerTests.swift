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
    private var fileLogger: FileLogger!

    override func setUp() {
        super.setUp()

        userDefaults = UserDefaults(suiteName: "testUserDefaults")!
        fileManager = FileManager.default
      
        fileLogger = try! FileLogger(
            fileManager: fileManager,
            userDefaults: userDefaults,
            externalLogger: { _ in },
            suiteName: nil,
            logDirectoryName: "logs",
            fileHeaderContent: "Test file header",
            numberOfLogFiles: 3
        )
    }

    override func tearDown() {
        try! FileManager.default.removeItem(atPath: fileLogger.logDirURL.path)
        fileLogger = nil

        userDefaults.removePersistentDomain(forName: "testUserDefaults")
        userDefaults = nil

        fileManager = nil

        super.tearDown()
    }

    func test_inicialization_of_FileLogger() {
        XCTAssertTrue(fileManager.directoryExists(at: fileLogger.logDirURL))
        XCTAssertEqual(try! fileManager.numberOfFiles(inDirectory: fileLogger.logDirURL), 0)

        let currentLogFileNumber = userDefaults.object(forKey: Constants.UserDefaultsKeys.currentLogFileNumber) as? Int
        XCTAssertEqual(currentLogFileNumber, 0)

        let dateOfLastLog = userDefaults.object(forKey: Constants.UserDefaultsKeys.dateOfLastLog) as? Date
        XCTAssertNotNil(dateOfLastLog)

        let numberOfLogFiles = userDefaults.object(forKey: Constants.UserDefaultsKeys.numberOfLogFiles) as? Int
        XCTAssertEqual(numberOfLogFiles, 3)
    }

    func test_archive_availability() {
        fileLogger.log(.mock("Error message"))
        fileLogger.log(.mock("Warning message"))

        // Archived log files check
        let archiveUrl = try! fileLogger.archiveWithLogFiles(withFileName: "logs")
        XCTAssertNotNil(archiveUrl)
        XCTAssertTrue(try! archiveUrl!.checkResourceIsReachable())
        try! FileManager.default.removeItem(at: archiveUrl!)
    }

    func test_file_rotation() {
        // Day 1 == File 0
        fileLogger.log(.mock("Warning message"))

        XCTAssertEqual(fileLogger.currentLogFileNumber, 0)
        XCTAssertEqual(
          fileLogger.currentLogFileUrl,
          fileLogger.logDirURL.appendingPathComponent("0").appendingPathExtension("log")
        )

        // Day 2 == File 1
        fileLogger.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLogger.dateOfLastLog)!

        fileLogger.log(.mock("Warning message"))

        XCTAssertEqual(fileLogger.currentLogFileNumber, 1)
        XCTAssertEqual(
            fileLogger.currentLogFileUrl,
            fileLogger.logDirURL.appendingPathComponent("1").appendingPathExtension("log")
        )

        // Day 3 == File 2
        fileLogger.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLogger.dateOfLastLog)!

        fileLogger.log(.mock("Warning message"))

        XCTAssertEqual(fileLogger.currentLogFileNumber, 2)
        XCTAssertEqual(
            fileLogger.currentLogFileUrl,
            fileLogger.logDirURL.appendingPathComponent("2").appendingPathExtension("log")
        )

       // Day 4 == File 0
        fileLogger.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLogger.dateOfLastLog)!

        fileLogger.log(.mock("Warning message"))

        XCTAssertEqual(fileLogger.currentLogFileNumber, 0)
        XCTAssertEqual(
            fileLogger.currentLogFileUrl,
            fileLogger.logDirURL.appendingPathComponent("0").appendingPathExtension("log")
        )

        XCTAssertEqual(try! fileManager.numberOfFiles(inDirectory: fileLogger.logDirURL), 3)
    }

    func test_single_logging_file() {
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

        let fileLogs = try! fileLogger.gettingRecordsFromLogFile(at: fileLogger.currentLogFileUrl)

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
