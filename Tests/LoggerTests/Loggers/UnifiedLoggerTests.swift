@testable import Logger
import OSLog
import XCTest

class UnifiedLoggerTests: XCTestCase {

    func test_message() {
        let message = "Testing log"
        let logEntry = LogEntry.mock(message)

        let unifiedLogger = { (type: OSLogType, message: String) in
            let expectedMessage = """
            ⚪️ \(logEntry.location.fileName) — \(logEntry.location.function) — line \(logEntry.location.line): \
            Testing log
            """

            XCTAssertEqual(type, OSLogType.info)
            XCTAssertEqual(message, expectedMessage)
        }

        let logger = UnifiedLogger(
            bundleIdentifier: "cz.qase.swift-logger-tests",
            unifiedLogger: unifiedLogger
        )

        logger.log(logEntry)
    }
}
