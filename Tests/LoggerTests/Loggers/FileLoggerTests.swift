//
//  FileLoggerTests.swift
//  
//
//  Created by Martin Troup on 30.09.2021.
//

@testable import Logger
import XCTest

private extension FileAccessExecutor {
    static var syncMock: Self {
        .init { $0() }
    }
}

class FileLoggerTests: XCTestCase {
    private var fileManager: FileManager!
    private var userDefaults: UserDefaults!
    private var logDirURL: URL!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        
        suiteName = UUID().uuidString
        
        self.fileManager = FileManager.default
        self.userDefaults = UserDefaults(suiteName: suiteName)!

        self.logDirURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(UUID().uuidString)

        if fileManager.directoryExists(at: logDirURL) {
            try! fileManager.removeItem(atPath: logDirURL.path)
        }

        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)

        if fileManager.directoryExists(at: logDirURL) {
            try! fileManager.removeItem(atPath: logDirURL.path)
        }

        super.tearDown()
    }

    func test_inicialization_of_FileLogger_with_specified_namespace() throws {
        let namespace = "test-namespace"

        _ = try FileLogger(
            appName: nil,
            fileManager: fileManager,
            userDefaults: userDefaults,
            logDirURL: logDirURL,
            namespace: namespace,
            numberOfLogFiles: 3,
            dateFormatter: DateFormatter.dateFormatter,
            fileHeaderContent: "",
            lineSeparator: "<-->",
            logEntryEncoder: LogEntryEncoder(),
            logEntryDecoder: LogEntryDecoder(),
            externalLogger: { _ in },
            fileAccessQueue: .syncMock
        )

        XCTAssertTrue(fileManager.directoryExists(at: logDirURL))
        XCTAssertEqual(try fileManager.numberOfFiles(inDirectory: logDirURL), 0)

        let currentLogFileNumber = userDefaults.object(
            forKey: "test-namespace-\(Constants.UserDefaultsKeys.currentLogFileNumber)"
        ) as? Int
        XCTAssertEqual(currentLogFileNumber, 0)

        let dateOfLastLog = userDefaults.object(forKey: "\(namespace)-\(Constants.UserDefaultsKeys.dateOfLastLog)") as? Date
        XCTAssertNotNil(dateOfLastLog)

        let numberOfLogFiles = userDefaults.object(forKey: "\(namespace)-\(Constants.UserDefaultsKeys.numberOfLogFiles)") as? Int
        XCTAssertEqual(numberOfLogFiles, 3)
    }

    func test_inicialization_of_FileLogger_without_specified_namespace() throws {
        _ = try FileLogger(
            appName: nil,
            fileManager: fileManager,
            userDefaults: userDefaults,
            logDirURL: logDirURL,
            namespace: nil,
            numberOfLogFiles: 3,
            dateFormatter: DateFormatter.dateFormatter,
            fileHeaderContent: "",
            lineSeparator: "<-->",
            logEntryEncoder: LogEntryEncoder(),
            logEntryDecoder: LogEntryDecoder(),
            externalLogger: { _ in },
            fileAccessQueue: .syncMock
        )

        XCTAssertTrue(fileManager.directoryExists(at: logDirURL))
        XCTAssertEqual(try! fileManager.numberOfFiles(inDirectory: logDirURL), 0)

        let currentLogFileNumber = userDefaults.object(forKey: Constants.UserDefaultsKeys.currentLogFileNumber) as? Int
        XCTAssertEqual(currentLogFileNumber, 0)

        let dateOfLastLog = userDefaults.object(forKey: Constants.UserDefaultsKeys.dateOfLastLog) as? Date
        XCTAssertNotNil(dateOfLastLog)

        let numberOfLogFiles = userDefaults.object(forKey: Constants.UserDefaultsKeys.numberOfLogFiles) as? Int
        XCTAssertEqual(numberOfLogFiles, 3)
    }

    func test_log_file_with_specified_appName() throws {
        let appName = "test-app-name"

        let fileLogger = try FileLogger(
            appName: appName,
            fileManager: fileManager,
            userDefaults: userDefaults,
            logDirURL: logDirURL,
            namespace: nil,
            numberOfLogFiles: 3,
            dateFormatter: DateFormatter.dateFormatter,
            fileHeaderContent: "",
            lineSeparator: "<-->",
            logEntryEncoder: LogEntryEncoder(),
            logEntryDecoder: LogEntryDecoder(),
            externalLogger: { _ in },
            fileAccessQueue: .syncMock
        )

        XCTAssertEqual(
            fileLogger.currentLogFileUrl,
            logDirURL.appendingPathComponent("\(appName)-0").appendingPathExtension("log")
        )
    }

    func test_log_file_without_specified_appName() throws {
        let fileLogger = try FileLogger(
            appName: nil,
            fileManager: fileManager,
            userDefaults: userDefaults,
            logDirURL: logDirURL,
            namespace: nil,
            numberOfLogFiles: 3,
            dateFormatter: DateFormatter.dateFormatter,
            fileHeaderContent: "",
            lineSeparator: "<-->",
            logEntryEncoder: LogEntryEncoder(),
            logEntryDecoder: LogEntryDecoder(),
            externalLogger: { _ in }
        )

        XCTAssertEqual(
            fileLogger.currentLogFileUrl,
            logDirURL.appendingPathComponent("0").appendingPathExtension("log")
        )
    }

    func test_log_files_availability() throws {
        let fileLogger = try FileLogger(
            appName: nil,
            fileManager: fileManager,
            userDefaults: userDefaults,
            logDirURL: logDirURL,
            namespace: nil,
            numberOfLogFiles: 3,
            dateFormatter: DateFormatter.dateFormatter,
            fileHeaderContent: "",
            lineSeparator: "<-->",
            logEntryEncoder: LogEntryEncoder(),
            logEntryDecoder: LogEntryDecoder(),
            externalLogger: { _ in },
            fileAccessQueue: .syncMock
        )

        // Day 1 == File 0
        fileLogger.log(.mock("Warning message"))

        // Day 2 == File 1
        fileLogger.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLogger.dateOfLastLog)!

        fileLogger.log(.mock("Warning message"))

        let sortedLogFiles = try fileLogger.logFiles.sorted(by: { $0.absoluteString < $1.absoluteString })

        XCTAssertEqual(sortedLogFiles.count, 2)

        sortedLogFiles.enumerated().forEach { index, item in
            XCTAssertEqual(
                item,
                logDirURL.appendingPathComponent("\(index)").appendingPathExtension("log")
            )
        }
    }

    func test_failed_write_is_reported_instead_of_crashing() throws {
        var internalErrors: [String] = []

        let fileLogger = try FileLogger(
            appName: nil,
            fileManager: fileManager,
            userDefaults: userDefaults,
            logDirURL: logDirURL,
            namespace: nil,
            numberOfLogFiles: 3,
            dateFormatter: DateFormatter.dateFormatter,
            fileHeaderContent: "",
            lineSeparator: "\n",
            logEntryEncoder: LogEntryEncoder(),
            logEntryDecoder: LogEntryDecoder(),
            externalLogger: { internalErrors.append($0) },
            fileAccessQueue: .syncMock
        )

        fileLogger.log(.mock("First message"))

        // Simulate an I/O failure (e.g. "No space left on device") with a handle that cannot be written to.
        // The legacy `seekToEndOfFile()` / `write(_:)` API raised an uncatchable NSException here and crashed the app.
        fileLogger.currentWritableFileHandle = try FileHandle(forReadingFrom: fileLogger.currentLogFileUrl)

        fileLogger.log(.mock("Second message"))

        XCTAssertEqual(internalErrors.count, 1)
        XCTAssertTrue(internalErrors.first?.hasPrefix("Failed to write to a log file") == true, internalErrors.description)

        let content = try String(contentsOf: fileLogger.currentLogFileUrl, encoding: .utf8)
        XCTAssertTrue(content.contains("First message"), content)
        XCTAssertFalse(content.contains("Second message"), content)
    }

    func test_file_rotation() throws {
        let fileLogger = try FileLogger(
            appName: nil,
            fileManager: fileManager,
            userDefaults: userDefaults,
            logDirURL: logDirURL,
            namespace: nil,
            numberOfLogFiles: 3,
            dateFormatter: DateFormatter.dateFormatter,
            fileHeaderContent: "",
            lineSeparator: "\n",
            logEntryEncoder: LogEntryEncoder(),
            logEntryDecoder: LogEntryDecoder(),
            externalLogger: { _ in },
            fileAccessQueue: .syncMock
        )

        // Day 1 == File 0
        fileLogger.log(.mock("Warning message"))

        XCTAssertEqual(fileLogger.currentLogFileNumber, 0)
        XCTAssertEqual(
          fileLogger.currentLogFileUrl,
          logDirURL.appendingPathComponent("0").appendingPathExtension("log")
        )

        var fileLogs = try! fileLogger.gettingRecordsFromLogFile(at: fileLogger.currentLogFileUrl)
        XCTAssertEqual(fileLogs.count, 1)

        // Day 2 == File 1
        fileLogger.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLogger.dateOfLastLog)!

        fileLogger.log(.mock("Warning message"))

        XCTAssertEqual(fileLogger.currentLogFileNumber, 1)
        XCTAssertEqual(
            fileLogger.currentLogFileUrl,
            logDirURL.appendingPathComponent("1").appendingPathExtension("log")
        )

        fileLogs = try! fileLogger.gettingRecordsFromLogFile(at: fileLogger.currentLogFileUrl)
        XCTAssertEqual(fileLogs.count, 1)

        // Day 3 == File 2
        fileLogger.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLogger.dateOfLastLog)!

        fileLogger.log(.mock("Warning message"))

        XCTAssertEqual(fileLogger.currentLogFileNumber, 2)
        XCTAssertEqual(
            fileLogger.currentLogFileUrl,
            logDirURL.appendingPathComponent("2").appendingPathExtension("log")
        )

        fileLogs = try! fileLogger.gettingRecordsFromLogFile(at: fileLogger.currentLogFileUrl)
        XCTAssertEqual(fileLogs.count, 1)

       // Day 4 == File 0
        fileLogger.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLogger.dateOfLastLog)!

        fileLogger.log(.mock("Warning message"))

        XCTAssertEqual(fileLogger.currentLogFileNumber, 0)
        XCTAssertEqual(
            fileLogger.currentLogFileUrl,
            logDirURL.appendingPathComponent("0").appendingPathExtension("log")
        )

        fileLogs = try! fileLogger.gettingRecordsFromLogFile(at: fileLogger.currentLogFileUrl)
        XCTAssertEqual(fileLogs.count, 1)

        XCTAssertEqual(try! fileManager.numberOfFiles(inDirectory: logDirURL), 3)
    }

    func test_single_logging_file() throws {
        let fileLogger = try FileLogger(
            appName: nil,
            fileManager: fileManager,
            userDefaults: userDefaults,
            logDirURL: logDirURL,
            namespace: nil,
            numberOfLogFiles: 3,
            dateFormatter: DateFormatter.dateFormatter,
            fileHeaderContent: "",
            lineSeparator: "<-->",
            logEntryEncoder: LogEntryEncoder(),
            logEntryDecoder: LogEntryDecoder(),
            externalLogger: { _ in },
            fileAccessQueue: .syncMock
        )

        fileLogger.levels = [.warning]

        let date = Date(timeIntervalSince1970: 0)

        fileLogger.log(
            LogEntry(
                header: LogHeader(date: date, level: .info),
                location: LogLocation(fileName: "file", function: "function", line: 1),
                message: "Error message"
            )
        )

        fileLogger.log(
            LogEntry(
                header: LogHeader(date: date, level: .info),
                location: LogLocation(fileName: "file2", function: "function2", line: 20),
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
        let fileLogger = try FileLogger(
            appName: nil,
            fileManager: fileManager,
            userDefaults: userDefaults,
            logDirURL: logDirURL,
            namespace: nil,
            numberOfLogFiles: 3,
            dateFormatter: DateFormatter.dateFormatter,
            fileHeaderContent: "",
            lineSeparator: "<-->",
            logEntryEncoder: LogEntryEncoder(),
            logEntryDecoder: LogEntryDecoder(),
            externalLogger: { _ in },
            fileAccessQueue: .syncMock
        )

        fileLogger.levels = [.warning]

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
            LogEntry(
                header: LogHeader(date: date, level: .info),
                location: LogLocation(fileName: "File.swift", function: "Function", line: 1),
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
        let fileLogger = try FileLogger(
            appName: nil,
            fileManager: fileManager,
            userDefaults: userDefaults,
            logDirURL: logDirURL,
            namespace: nil,
            numberOfLogFiles: 3,
            dateFormatter: DateFormatter.dateFormatter,
            fileHeaderContent: "",
            lineSeparator: "<-->",
            logEntryEncoder: LogEntryEncoder(),
            logEntryDecoder: LogEntryDecoder(),
            externalLogger: { _ in },
            fileAccessQueue: .syncMock
        )

        fileLogger.levels = [.warning]

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
            LogEntry(
                header: LogHeader(date: date, level: .info),
                location: LogLocation(fileName: "File.swift", function: "Function", line: 1),
                message: encodedCodableString
            )
        )
        fileLogger.log(
            LogEntry(
                header: LogHeader(date: date, level: .info),
                location: LogLocation(fileName: "File2.swift", function: "Function2", line: 2),
                message: "Special characters ::[]{}()//"
            )
        )
        fileLogger.log(
            LogEntry(
                header: LogHeader(date: date, level: .info),
                location: LogLocation(fileName: "File3.swift", function: "Function3", line: 3),
                message: """
                    line 1
                    line 2
                    line 3
                    """
            )
        )
        fileLogger.log(
            LogEntry(
                header: LogHeader(date: date, level: .info),
                location: LogLocation(fileName: "File3.swift", function: "Function3", line: 3),
                message: "[🚗] Some message"
            )
        )
        fileLogger.log(
            LogEntry(
                header: LogHeader(date: date, level: .info),
                location: LogLocation(fileName: "File4.swift", function: "Function4", line: 4),
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
    
    func test_deleting_log_files_resets_the_logger_configuration() throws {
        let fileLogger = try FileLogger(
            appName: nil,
            fileManager: fileManager,
            userDefaults: userDefaults,
            logDirURL: logDirURL,
            namespace: nil,
            numberOfLogFiles: 3,
            dateFormatter: DateFormatter.dateFormatter,
            fileHeaderContent: "",
            lineSeparator: "<-->",
            logEntryEncoder: LogEntryEncoder(),
            logEntryDecoder: LogEntryDecoder(),
            externalLogger: { _ in },
            fileAccessQueue: .syncMock
        )

        let date = Date(timeIntervalSince1970: 0)

        fileLogger.log(
            LogEntry(
                header: LogHeader(date: date, level: .info),
                location: LogLocation(fileName: "file", function: "function", line: 1),
                message: "Error message"
            )
        )

        fileLogger.log(
            LogEntry(
                header: LogHeader(date: date, level: .info),
                location: LogLocation(fileName: "file2", function: "function2", line: 20),
                message: "Warning message\nThis is test!"
            )
        )

        let fileLogs = try! fileLogger.gettingRecordsFromLogFile(at: fileLogger.currentLogFileUrl)

        XCTAssertEqual(fileLogs.count, 2)
        
        fileLogger.deleteAllLogFiles()
        
        fileLogger.log(
            LogEntry(
                header: LogHeader(date: date, level: .info),
                location: LogLocation(fileName: "file3", function: "function3", line: 30),
                message: "Previous logs were deleted."
            )
        )
        
        let fileLogsAfterDelete = try! fileLogger.gettingRecordsFromLogFile(at: fileLogger.currentLogFileUrl)
        
        XCTAssertEqual(fileLogsAfterDelete.count, 1)
        XCTAssertEqual(fileLogsAfterDelete[0].message.description, "Previous logs were deleted.")
    }
    
    func test_fileLogger_multithreading_delete_and_log_simultaneously() throws {
        let fileAccessGroup = DispatchGroup()
        let fileAccessQueue = DispatchQueue(label: "FileLoggerTests.fileAccessQueue")
        let fileAccessExecutor = FileAccessExecutor { job in
            fileAccessGroup.enter()
            fileAccessQueue.async(execute: DispatchWorkItem {
                defer { fileAccessGroup.leave() }
                job()
            })
        }

        let fileLogger = try FileLogger(
            appName: nil,
            fileManager: fileManager,
            userDefaults: userDefaults,
            logDirURL: logDirURL,
            namespace: nil,
            numberOfLogFiles: 100,
            dateFormatter: DateFormatter.dateFormatter,
            fileHeaderContent: "",
            lineSeparator: "<-->",
            logEntryEncoder: LogEntryEncoder(),
            logEntryDecoder: LogEntryDecoder(),
            externalLogger: { _ in },
            fileAccessQueue: fileAccessExecutor
        )
        
        let logCounter = Counter()
        let deleteCounter = Counter()
        let dispatchGroup = DispatchGroup()

        for _ in 1...100 {
            dispatchGroup.enter()
            DispatchQueue.global().async(execute: DispatchWorkItem {
                fileLogger.log(
                    LogEntry(
                        header: LogHeader(date: Date(), level: .info),
                        location: LogLocation(fileName: "File", function: "function", line: 1),
                        message: "Error message"
                    )
                )
                logCounter.increment()
                dispatchGroup.leave()
            })
        }
        for _ in 1...50 {
            dispatchGroup.enter()
            DispatchQueue.global().async(execute: DispatchWorkItem {
                fileLogger.deleteAllLogFiles()
                deleteCounter.increment()
                dispatchGroup.leave()
            })
        }

        let result = dispatchGroup.wait(timeout: .now() + 1.0)
        XCTAssertEqual(fileAccessGroup.wait(timeout: .now() + 1.0), .success)

        switch result {
        case .success:
            XCTAssertEqual(logCounter.value(), 100)
            XCTAssertEqual(deleteCounter.value(), 50)

        case .timedOut:
            XCTFail("Timed out waiting for concurrent log and delete operations.")
        }
    }

    func test_deleting_log_files_from_outside() throws {
        let fileLogger = try FileLogger(
            appName: nil,
            fileManager: fileManager,
            userDefaults: userDefaults,
            logDirURL: logDirURL,
            namespace: nil,
            numberOfLogFiles: 3,
            dateFormatter: DateFormatter.dateFormatter,
            fileHeaderContent: "",
            lineSeparator: "<-->",
            logEntryEncoder: LogEntryEncoder(),
            logEntryDecoder: LogEntryDecoder(),
            externalLogger: { _ in },
            fileAccessQueue: .syncMock
        )

        let date = Date(timeIntervalSince1970: 0)

        fileLogger.log(
            LogEntry(
                header: LogHeader(date: date, level: .info),
                location: LogLocation(fileName: "file", function: "function", line: 1),
                message: "Error message"
            )
        )

        fileLogger.log(
            LogEntry(
                header: LogHeader(date: date, level: .info),
                location: LogLocation(fileName: "file2", function: "function2", line: 20),
                message: "Warning message\nThis is test!"
            )
        )

        let fileLogs = try! fileLogger.gettingRecordsFromLogFile(at: fileLogger.currentLogFileUrl)

        XCTAssertEqual(fileLogs.count, 2)

        try fileManager.deleteAllFiles(at: logDirURL, withPathExtension: "log")

        fileLogger.log(
            LogEntry(
                header: LogHeader(date: date, level: .info),
                location: LogLocation(fileName: "file3", function: "function3", line: 30),
                message: "Previous logs were deleted."
            )
        )

        let fileLogsAfterDelete = try! fileLogger.gettingRecordsFromLogFile(at: fileLogger.currentLogFileUrl)

        XCTAssertEqual(fileLogsAfterDelete.count, 1)
        XCTAssertEqual(fileLogsAfterDelete[0].message.description, "Previous logs were deleted.")
    }
}

// MARK: - FileManager + helper functions

private extension FileLoggerTests {
    struct MockedCodable: Codable {
        var int: Int
        var string: String
        var array: [MockedCodable]
    }
}
