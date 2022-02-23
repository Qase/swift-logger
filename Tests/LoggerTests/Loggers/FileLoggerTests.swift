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

        let date = Date(timeIntervalSince1970: 0)

        fileLogger.log(
            .init(
                header: .init(date: date, level: .info, dateFormatter: DateFormatter.dateTimeFormatter),
                location: .init(fileName: "file", function: "function", line: 1),
                message: "Error message"
            )
        )

        fileLogger.log(
            .init(
                header: .init(date: date, level: .info, dateFormatter: DateFormatter.dateTimeFormatter),
                location: .init(fileName: "file2", function: "function2", line: 20),
                message: "Warning message\nThis is test!"
            )
        )

        let fileLogs = try! fileLogger.gettingRecordsFromLogFile(at: fileLogger.currentLogFileUrl)

        XCTAssertEqual(fileLogs.count, 2)

        XCTAssertEqual(fileLogs.first?.header.level, .info)
        XCTAssertEqual(fileLogs.first?.header.date, date)
        XCTAssertEqual(fileLogs.first?.location.fileName, "file")
        XCTAssertEqual(fileLogs.first?.location.function, "function")
        XCTAssertEqual(fileLogs.first?.location.line, 1)
        XCTAssertEqual(fileLogs.first?.body, "Error message")

        XCTAssertEqual(fileLogs.last?.header.level, .info)
        XCTAssertEqual(fileLogs.last?.header.date, date)
        XCTAssertEqual(fileLogs.last?.location.fileName, "file2")
        XCTAssertEqual(fileLogs.last?.location.function, "function2")
        XCTAssertEqual(fileLogs.last?.location.line, 20)
        XCTAssertEqual(fileLogs.last?.body, "Warning message\nThis is test!")
    }

    func test_encoding_and_decoding_codable() throws {
        let fileLogger = try FileLogger()
        fileLogger.levels = [.error, .warn]

        let codable = MockedCodable(
            int: 42,
            string: "Test",
            array: [
                MockedCodable(
                    int: 42,
                    string: "Test",
                    array: []
                )
            ]
        )

        let data = try JSONEncoder().encode(codable)
        let encodedCodableString = String(data: data, encoding: .utf16)!
        let date = Date(timeIntervalSince1970: 0)

        fileLogger.log(
            .init(
                header: .init(date: date, level: .info, dateFormatter: DateFormatter.dateTimeFormatter),
                location: .init(fileName: "File.swift", function: "Function", line: 1),
                message: encodedCodableString
            )
        )

        let fileLogs = try! fileLogger.gettingRecordsFromLogFile(at: fileLogger.currentLogFileUrl)

        XCTAssertEqual(fileLogs.count, 1)

        XCTAssertEqual(fileLogs.first?.header.level.rawValue, Level.info.rawValue)
        XCTAssertEqual(fileLogs.first?.header.date, date)
        XCTAssertEqual(fileLogs.first?.location.fileName, "File.swift")
        XCTAssertEqual(fileLogs.first?.location.function, "Function")
        XCTAssertEqual(fileLogs.first?.location.line, 1)
        XCTAssertEqual(fileLogs.first?.body, encodedCodableString)
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

private extension FileLoggerTests {
    struct MockedCodable: Codable {
        var int: Int
        var string: String
        var array: [MockedCodable]
    }
}
