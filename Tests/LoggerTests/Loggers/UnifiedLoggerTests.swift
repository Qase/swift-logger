@testable import Logger
import OSLog
import XCTest

class UnifiedLoggerTests: XCTestCase {

    func test_UnifiedLogger_message_with_prefix() {
        let message = "Testing log with prefix"
        let logEntry = LogEntry.mock(message)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "CS_cz")

        let dateString = formatter.string(from: logEntry.header.date)

        let unifiedLogger = { (type: OSLogType, message: String) in
            let expectedMessage = """
            |> [\(logEntry.header.level.rawValue) \(dateString)] \
            \(logEntry.location.fileName) — \(logEntry.location.function) — line \(logEntry.location.line): \
            Testing log with prefix
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
