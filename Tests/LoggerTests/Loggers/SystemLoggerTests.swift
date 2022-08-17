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

        let logEntry = LogEntry.mock(message)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "CS_cz")

        let dateString = formatter.string(from: logEntry.header.date)

        let systemLogger = { (type: OSLogType, message: String) in
            let expectedMessage = """
            \(prefix):|> [\(logEntry.header.level.rawValue.uppercased()) \(dateString)] \
            \(logEntry.location.fileName) — \(logEntry.location.function) — line \(logEntry.location.line): \
            Testing log with prefix
            """

            XCTAssertEqual(type, OSLogType.info)
            XCTAssertEqual(message, expectedMessage)
        }

        let logger = SystemLogger(
            systemLogger: systemLogger,
            prefix: prefix
        )

        logger.log(logEntry)
    }
}
