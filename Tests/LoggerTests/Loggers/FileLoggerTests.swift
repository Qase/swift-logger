//
//  FileLoggerTests.swift
//  
//
//  Created by Martin Troup on 30.09.2021.
//

@testable import Logger
import XCTest

class FileLoggerTests: XCTestCase {
    private var fileLogger: FileLogger!
    private let appGroupID = "test-appGroupID"
    private let suiteName = "test-suiteName"

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: appGroupID)
        UserDefaults.standard.removePersistentDomain(forName: suiteName)

        try! FileManager.default.removeItem(atPath: fileLogger.logDirURL.path)

        fileLogger = nil

        super.tearDown()
    }

    func test_inicialization_of_FileLogger() {
        fileLogger = try! FileLogger(sharingConfiguration: .nonShared(suiteName: suiteName),numberOfLogFiles: 3)

        XCTAssertTrue(fileLogger.fileManager.directoryExists(at: fileLogger.logDirURL))
        XCTAssertEqual(try! fileLogger.fileManager.numberOfFiles(inDirectory: fileLogger.logDirURL), 0)

        let currentLogFileNumber = fileLogger.userDefaults.object(
            forKey: Constants.UserDefaultsKeys.currentLogFileNumber
        ) as? Int
        XCTAssertEqual(currentLogFileNumber, 0)

        let dateOfLastLog = fileLogger.userDefaults.object(forKey: Constants.UserDefaultsKeys.dateOfLastLog) as? Date
        XCTAssertNotNil(dateOfLastLog)

        let numberOfLogFiles = fileLogger.userDefaults.object(
            forKey: Constants.UserDefaultsKeys.numberOfLogFiles
        ) as? Int
        XCTAssertEqual(numberOfLogFiles, 3)
    }

    func test_log_files_availability() {
        fileLogger = try! FileLogger(sharingConfiguration: .nonShared(suiteName: suiteName), numberOfLogFiles: 3)

        // Day 1 == File 0
        fileLogger.log(.mock("Warning message"))

        // Day 2 == File 1
        fileLogger.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLogger.dateOfLastLog)!

        fileLogger.log(.mock("Warning message"))

        // Day 3 == File 2
        fileLogger.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLogger.dateOfLastLog)!

        fileLogger.log(.mock("Warning message"))

        let logFiles = try! fileLogger.logFiles

        XCTAssertEqual(logFiles.count, 3)
        logFiles.enumerated().forEach { index, item in
            if item.absoluteString.filter({ "0"..."9" ~= $0 }) == "\(index)" {
                XCTAssertEqual(
                    item,
                    fileLogger.logDirURL.appendingPathComponent("\(index)").appendingPathExtension("log")
                )
            }
        }
    }

    func test_fileName_without_explicit_appName() {
        fileLogger = try! FileLogger(appName: nil, sharingConfiguration: .nonShared(suiteName: suiteName))

        XCTAssertEqual(
            fileLogger.currentLogFileUrl,
            fileLogger.logDirURL.appendingPathComponent("0").appendingPathExtension("log")
        )
    }

    func test_fileName_with_explicit_appName() {
        fileLogger = try! FileLogger(appName: "MainApp", sharingConfiguration: .nonShared(suiteName: suiteName))
        XCTAssertEqual(
            fileLogger.currentLogFileUrl,
            fileLogger.logDirURL.appendingPathComponent("MainApp-0").appendingPathExtension("log")
        )
    }

    func test_log_directory_not_shared_when_nonShared_configuration_set() {
        fileLogger = try! FileLogger(
            sharingConfiguration: .nonShared(suiteName: suiteName),
            logDirectoryName: "test-logs"
        )

        let expectedURL = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
            .appendingPathComponent("test-logs", isDirectory: false)

        XCTAssertEqual(expectedURL, fileLogger.logDirURL)
    }

    func test_log_directory_shared_when_shared_configuration_set() {
        fileLogger = try! FileLogger(
            sharingConfiguration: .shared(appGroupID: appGroupID),
            logDirectoryName: "test-logs"
        )

        let expectedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("test-logs", isDirectory: false)

        XCTAssertEqual(expectedURL, fileLogger.logDirURL)
    }

    func test_file_rotation() {
        fileLogger = try! FileLogger(sharingConfiguration: .nonShared(suiteName: suiteName), numberOfLogFiles: 3)

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

        XCTAssertEqual(try! fileLogger.fileManager.numberOfFiles(inDirectory: fileLogger.logDirURL), 3)
    }

    func test_single_logging_file() {
        fileLogger = try! FileLogger(sharingConfiguration: .nonShared(suiteName: suiteName))

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
        XCTAssertEqual(fileLogs.first?.message.description, "Error message")

        XCTAssertEqual(fileLogs.last?.header.level, .info)
        XCTAssertEqual(fileLogs.last?.header.date, date)
        XCTAssertEqual(fileLogs.last?.location.fileName, "file2")
        XCTAssertEqual(fileLogs.last?.location.function, "function2")
        XCTAssertEqual(fileLogs.last?.location.line, 20)
        XCTAssertEqual(fileLogs.last?.message.description, "Warning message\nThis is test!")
    }

    func test_encoding_and_decoding_codable() throws {
        fileLogger = try! FileLogger(sharingConfiguration: .nonShared(suiteName: suiteName))

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
        let encodedCodableString = String(data: data, encoding: .utf8)!
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
        XCTAssertEqual(fileLogs.first?.message.description, encodedCodableString)
    }

    func test_encoding_and_decoding_several_logs() throws {
        fileLogger = try! FileLogger(sharingConfiguration: .nonShared(suiteName: suiteName))

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
        let encodedCodableString = String(data: data, encoding: .utf8)!
        let date = Date(timeIntervalSince1970: 0)

        fileLogger.log(
            .init(
                header: .init(date: date, level: .info, dateFormatter: DateFormatter.dateTimeFormatter),
                location: .init(fileName: "File.swift", function: "Function", line: 1),
                message: encodedCodableString
            )
        )
        fileLogger.log(
            .init(
                header: .init(date: date, level: .info, dateFormatter: DateFormatter.dateTimeFormatter),
                location: .init(fileName: "File2.swift", function: "Function2", line: 2),
                message: "Special characters ::[]{}()//"
            )
        )
        fileLogger.log(
            .init(
                header: .init(date: date, level: .info, dateFormatter: DateFormatter.dateTimeFormatter),
                location: .init(fileName: "File3.swift", function: "Function3", line: 3),
                message: """
                    line 1
                    line 2
                    line 3
                    """
            )
        )
        fileLogger.log(
            .init(
                header: .init(date: date, level: .info, dateFormatter: DateFormatter.dateTimeFormatter),
                location: .init(fileName: "File3.swift", function: "Function3", line: 3),
                message: "[🚗] Some message"
            )
        )
        fileLogger.log(
            .init(
                header: .init(date: date, level: .info, dateFormatter: DateFormatter.dateTimeFormatter),
                location: .init(fileName: "File4.swift", function: "Function4", line: 4),
                message: encodedCodableString
            )
        )

        let fileLogs = try! fileLogger.gettingRecordsFromLogFile(at: fileLogger.currentLogFileUrl)

        XCTAssertEqual(fileLogs.count, 5)

        XCTAssertEqual(fileLogs.first?.header.level.rawValue, Level.info.rawValue)
        XCTAssertEqual(fileLogs.first?.header.date, date)
        XCTAssertEqual(fileLogs.first?.location.fileName, "File.swift")
        XCTAssertEqual(fileLogs.first?.location.function, "Function")
        XCTAssertEqual(fileLogs.first?.location.line, 1)

        XCTAssertEqual(fileLogs[0].message.description, encodedCodableString)
        XCTAssertEqual(fileLogs[1].message.description, "Special characters ::[]{}()//")
        XCTAssertEqual(fileLogs[2].message.description, """
            line 1
            line 2
            line 3
            """
        )
        XCTAssertEqual(fileLogs[3].message.description, "[🚗] Some message")
        XCTAssertEqual(fileLogs[4].message.description, encodedCodableString)
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
