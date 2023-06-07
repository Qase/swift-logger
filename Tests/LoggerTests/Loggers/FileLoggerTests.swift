//
//  FileLoggerTests.swift
//  
//
//  Created by Martin Troup on 30.09.2021.
//

@testable import Logger
import XCTest
import Combine

class FileLoggerTests: XCTestCase {
    private var fileManager: FileManager!
    private var userDefaults: UserDefaults!
    private var logDirURL: URL!
    private let suiteName = "test-user-defaults"

    override func setUp() {
        super.setUp()

        self.fileManager = FileManager.default
        self.userDefaults = UserDefaults(suiteName: suiteName)!

        self.logDirURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("test-directory")

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
            externalLogger: { _ in }
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
            externalLogger: { _ in }
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
            externalLogger: { _ in }
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
        
        try fileLogger.deleteAllLogFiles()
        
        fileLogger.log(
            .init(
                header: .init(date: date, level: .info, dateFormatter: DateFormatter.dateTimeFormatter),
                location: .init(fileName: "file3", function: "function3", line: 30),
                message: "Previous logs were deleted."
            )
        )
        
        let fileLogsAfterDelete = try! fileLogger.gettingRecordsFromLogFile(at: fileLogger.currentLogFileUrl)
        
        XCTAssertEqual(fileLogsAfterDelete.count, 1)
        XCTAssertEqual(fileLogsAfterDelete[0].message.description, "Previous logs were deleted.")
    }
    
    func test_loggerManager_multithreading_delete_and_log_simultaneously() throws {
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
            externalLogger: { _ in }
        )
        
        var cancellables = Set<AnyCancellable>()
        let expectation = self.expectation(description: "")
        var logCount = 0
        var deleteCount = 0
        
        //Simple mutex by using semaphore with value 1
        let semaphore = DispatchSemaphore(value: 1)
        
        (1...100).publisher
            .flatMap { _ in
                Just(())
                    .subscribe(on: DispatchQueue.global())
                    .handleEvents(
                        receiveOutput: {
                            fileLogger.log(
                                .init(
                                    header: .init(date: Date(), level: .info, dateFormatter: DateFormatter.dateTimeFormatter),
                                    location: .init(fileName: "File", function: "function", line: 1),
                                    message: "Error message"
                                )
                            )
                            semaphore.wait()
                            logCount += 1
                            semaphore.signal()
                        }
                    )
            }
            .collect(2)
            .map { _ in }
            .flatMap {
                Just(())
                    .subscribe(on: DispatchQueue.global())
                    .handleEvents(
                        receiveOutput: {
                            try? fileLogger.deleteAllLogFiles()
                            semaphore.wait()
                            deleteCount += 1
                            semaphore.signal()
                        }
                    )
            }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(logCount, 100)
        XCTAssertEqual(deleteCount, 50)
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
