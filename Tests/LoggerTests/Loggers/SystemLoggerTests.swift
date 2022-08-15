//
//  SystemLoggerTests.swift
//  
//
//  Created by Jan Provaznik on 15.08.2022.
//

@testable import Logger
import OSLog
import XCTest

class SystemLoggerTests: XCTestCase {

    func test_SystemLogger_message_with_prefix() {
        let message = "Testing log with prefix"
        let prefix = "TESTLog"
        let logger = SystemLogger(
            subsystem: "test",
            category: "testLogging",
            prefix: prefix
        )

        let logEntry = LogEntry.mock(message)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let dateString = formatter.string(from: logEntry.header.date)

        XCTAssertEqual(
            logger.createMessageWithPrefix(.mock(message)),
            """
            \(prefix):|> [\(logEntry.header.level.rawValue.uppercased()) \(dateString)] \
            \(logEntry.location.fileName) — \(logEntry.location.function) — line \(logEntry.location.line): \(message)
            """
        )
    }
}
