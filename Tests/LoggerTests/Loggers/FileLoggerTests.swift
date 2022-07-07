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

    func clearUserDefaults(appGroupID: String? = nil) {
        guard let appGroupID = appGroupID else {
            if let domain = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
            } else {
                print("UserDefaults standard does not exist.")
            }
            return
        }

        UserDefaults.standard.removePersistentDomain(forName: appGroupID)
    }

    func test_inicialization_of_FileLogger() {
        fileLogger = try! FileLogger(
            appGroupID: "testUserDefaults",
            numberOfLogFiles: 3
        )

        XCTAssertTrue(fileLogger.fileManager.directoryExists(at: fileLogger.logDirURL))
        XCTAssertEqual(try! fileLogger.fileManager.numberOfFiles(inDirectory: fileLogger.logDirURL), 0)

        let currentLogFileNumber = fileLogger.userDefaults.object(forKey: Constants.UserDefaultsKeys.currentLogFileNumber) as? Int
        XCTAssertEqual(currentLogFileNumber, 0)

        let dateOfLastLog = fileLogger.userDefaults.object(forKey: Constants.UserDefaultsKeys.dateOfLastLog) as? Date
        XCTAssertNotNil(dateOfLastLog)

        let numberOfLogFiles = fileLogger.userDefaults.object(forKey: Constants.UserDefaultsKeys.numberOfLogFiles) as? Int
        XCTAssertEqual(numberOfLogFiles, 3)

        try! FileManager.default.removeItem(atPath: fileLogger.logDirURL.path)
        clearUserDefaults(appGroupID: "testUserDefaults")
    }

    func test_archive_availability() {
        fileLogger = try! FileLogger()

        fileLogger.log(.mock("Error message"))
        fileLogger.log(.mock("Warning message"))

        // Archived log files check
        let archiveUrl = try! fileLogger.archiveWithLogFiles(withFileName: "logs")
        XCTAssertNotNil(archiveUrl)
        XCTAssertTrue(try! archiveUrl!.checkResourceIsReachable())
        try! FileManager.default.removeItem(at: archiveUrl!)

        try! FileManager.default.removeItem(atPath: fileLogger.logDirURL.path)
        clearUserDefaults()
    }

    func test_file_identification() {
        fileLogger = try! FileLogger(appName: nil)
        XCTAssertEqual(
            fileLogger.currentLogFileUrl,
            fileLogger.logDirURL.appendingPathComponent("0").appendingPathExtension("log")
        )

        fileLogger = try! FileLogger(appName: "MainApp")
        XCTAssertEqual(
            fileLogger.currentLogFileUrl,
            fileLogger.logDirURL.appendingPathComponent("MainApp-0").appendingPathExtension("log")
        )

        fileLogger = try! FileLogger(appName: "Extension")
        XCTAssertEqual(
            fileLogger.currentLogFileUrl,
            fileLogger.logDirURL.appendingPathComponent("Extension-0").appendingPathExtension("log")
        )

        try! FileManager.default.removeItem(atPath: fileLogger.logDirURL.path)
        clearUserDefaults()
    }

    func test_appGroup_storage_reachability() {
        fileLogger = try! FileLogger(appGroupID: nil)
        XCTAssertFalse(fileLogger.logDirURL.absoluteString.contains("Shared"))

        try! FileManager.default.removeItem(atPath: fileLogger.logDirURL.path)
        clearUserDefaults()

        fileLogger = try! FileLogger(appGroupID: "shared")
        XCTAssertTrue(fileLogger.logDirURL.absoluteString.contains("Shared/AppGroup"))

        try! FileManager.default.removeItem(atPath: fileLogger.logDirURL.path)
        clearUserDefaults(appGroupID: "shared")
    }

    func test_file_rotation() {
        fileLogger = try! FileLogger(
            appGroupID: "testUserDefaults",
            numberOfLogFiles: 3
        )

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

        try! FileManager.default.removeItem(atPath: fileLogger.logDirURL.path)
        clearUserDefaults(appGroupID: "testUserDefaults")
    }

    func test_single_logging_file() {
        fileLogger = try! FileLogger()

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

        try! FileManager.default.removeItem(atPath: fileLogger.logDirURL.path)
        clearUserDefaults()
    }

    func test_encoding_and_decoding_codable() throws {
        fileLogger = try! FileLogger()

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

        try! FileManager.default.removeItem(atPath: fileLogger.logDirURL.path)
        clearUserDefaults()
    }

    func test_encoding_and_decoding_several_logs() throws {
        fileLogger = try! FileLogger()

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

        try! FileManager.default.removeItem(atPath: fileLogger.logDirURL.path)
        clearUserDefaults()
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
