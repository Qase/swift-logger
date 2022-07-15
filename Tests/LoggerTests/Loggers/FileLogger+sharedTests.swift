//
//  FileLogger+sharedTests.swift
//  
//
//  Created by Martin Troup on 14.07.2022.
//

@testable import Logger
import XCTest

class FileLogger_sharedTests: XCTestCase {
    private let appGroupID = "test-app-group-id"
    private let namespace = "test-namespace"
    private var fileManager: FileManager!
    private var userDefaults: UserDefaults!
    private var logDirURL: URL!

    override func setUp() {
        super.setUp()

        self.fileManager = FileManager.default
        self.userDefaults = UserDefaults(suiteName: appGroupID)!

        self.logDirURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
            .appendingPathComponent(namespace)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: appGroupID)
        
        if fileManager.directoryExists(at: logDirURL) {
            try! fileManager.removeItem(atPath: logDirURL.path)
        }

        super.tearDown()
    }
    
    func test_inicialization_of_FileLogger_with_shared_configuration() throws {
        let appName = "test-app-name"

        let fileLogger = try FileLogger(
            sharingConfiguration: .shared(
                appGroupID: appGroupID,
                maxNumberOfFiles: 3,
                appName: appName
            ),
            namespace: namespace,
            fileHeaderContent: "",
            lineSeparator: "\n",
            logEntryEncoder: LogEntryEncoder(),
            logEntryDecoder: LogEntryDecoder(),
            loggerForInternalErrors: { _ in }
        )

        XCTAssertTrue(fileManager.directoryExists(at: logDirURL))
        XCTAssertEqual(try fileManager.numberOfFiles(inDirectory: logDirURL), 0)

        XCTAssertEqual(
            fileLogger.currentLogFileUrl,
            logDirURL.appendingPathComponent("\(appName)-0").appendingPathExtension("log")
        )

        let currentLogFileNumber = userDefaults.object(
            forKey: "\(namespace)-\(Constants.UserDefaultsKeys.currentLogFileNumber)"
        ) as? Int
        XCTAssertEqual(currentLogFileNumber, 0)

        let dateOfLastLog = userDefaults.object(forKey: "\(namespace)-\(Constants.UserDefaultsKeys.dateOfLastLog)") as? Date
        XCTAssertNotNil(dateOfLastLog)

        let numberOfLogFiles = userDefaults.object(forKey: "\(namespace)-\(Constants.UserDefaultsKeys.numberOfLogFiles)") as? Int
        XCTAssertEqual(numberOfLogFiles, 3)
    }
}
