@testable import Logger
import OSLog
import XCTest

class NativeLogger_OSLogStoreTests: XCTestCase {

    struct LogEntryEncoderTest: LogEntryEncoding {
        func encode(_ logEntry: LogEntry, verbose: Bool) -> String {
            logEntry.message as! String
        }
    }

    func getOsLogStore() throws -> OSLogStore {
        try! OSLogStore(scope: .currentProcessIdentifier)
    }

    func test_empty_logstore() async throws {
        let logger = NativeLogger(
            bundleIdentifier: "cz.qase.swift-logger-tests",
            category: "NativeLogger_OSLogStoreTests",
            logEntryEncoder: LogEntryEncoderTest()
        )

        let logs = try await logger.exportLogs(fromDate: Date.distantPast, getOsLogStore: getOsLogStore)

        XCTAssertTrue(logs.isEmpty)
    }

    func test_get_entries() async throws {
        let logger = NativeLogger(
            bundleIdentifier: "cz.qase.swift-logger-tests",
            category: "NativeLogger_OSLogStoreTests",
            logEntryEncoder: LogEntryEncoderTest()
        )

        let message1 = "Testing log"
        let logEntry1 = LogEntry.mock(message1)
        logger.log(logEntry1)

        let message2 = "Testing log 2"
        let logEntry2 = LogEntry.mock(message2)
        logger.log(logEntry2)

        // Noticed that it doesn't really matter on which day you passed; it always returns all the logs.
        let date = Date.now.addingTimeInterval(-2*60)
        let logs = try await logger.exportLogs(fromDate: date, getOsLogStore: getOsLogStore)

        XCTAssertTrue(logs.count == 2)
        XCTAssertTrue(logs[0].composedMessage == message1)
        XCTAssertTrue(logs[1].composedMessage == message2)
    }
}
