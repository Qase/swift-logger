//
//  LogManagerTests.swift
//
//
//  Created by Martin Troup on 24.09.2021.
//

import XCTest
@testable import Logger

class LoggerTests: XCTestCase {

    override func setUp() {
        super.setUp()

        LogManager.shared.removeAllLoggers()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_LogManager() {
        let consoleLogger = ConsoleLogger()
        let fileLogger = FileLogger()

        _ = LogManager.shared.add(consoleLogger)
        _ = LogManager.shared.add(fileLogger)

        let retrievedConsoleLogger: ConsoleLogger? = LogManager.shared.logger()
        XCTAssertNotNil(retrievedConsoleLogger)

        LogManager.shared.remove(consoleLogger)
        let againRetrievedConsoleLogger: ConsoleLogger? = LogManager.shared.logger()
        XCTAssertNil(againRetrievedConsoleLogger)

        let retrievedFileLogger: FileLogger? = LogManager.shared.logger()
        XCTAssertNotNil(retrievedFileLogger)
    }
}
