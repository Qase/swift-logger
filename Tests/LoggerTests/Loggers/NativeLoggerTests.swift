@testable import Logger
import OSLog
import XCTest

class NativeLoggerTests: XCTestCase {

    func test_message() {
        let message = "Testing log"
        let logEntry = LogEntry.mock(message)

        let logger = { (type: OSLogType, message: String) in
            let expectedMessage = """
            ⚪️ \(logEntry.location.fileName) — \(logEntry.location.function) — line \(logEntry.location.line): \
            Testing log
            """

            XCTAssertEqual(type, OSLogType.info)
            XCTAssertEqual(message, expectedMessage)
        }

        let nativeLogger = NativeLogger(
            bundleIdentifier: "cz.qase.swift-logger-tests",
            logger: logger
        )

        nativeLogger.log(logEntry)
    }
}