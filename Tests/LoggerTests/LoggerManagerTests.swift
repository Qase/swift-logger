//
//  LoggerManagerTests.swift
//  
//
//  Created by Martin Ficek on 29.05.2023.
//

import XCTest
@testable import Logger

class LoggerManagerTests: XCTestCase {
    func test_log_delivers_to_synchronous_logger_immediately() {
        let logger = TestLogger(isAsynchronous: false)
        let loggerManager = LoggerManager(
            loggers: [logger],
            applicationCallbackLoggerBundle: nil,
            metaInformationLoggerBundle: nil
        )

        loggerManager.log("message", onLevel: .info)

        XCTAssertEqual(logger.loggedMessages, ["message"])
    }

    func test_log_does_not_block_on_asynchronous_logger() {
        let didLog = expectation(description: "async logger called")
        let shouldFinishLogging = DispatchSemaphore(value: 0)
        let logger = BlockingLogger(
            isAsynchronous: true,
            onLog: {
                shouldFinishLogging.wait()
                didLog.fulfill()
            }
        )
        let loggerManager = LoggerManager(
            loggers: [logger],
            applicationCallbackLoggerBundle: nil,
            metaInformationLoggerBundle: nil
        )

        loggerManager.log("message", onLevel: .info)
        shouldFinishLogging.signal()

        wait(for: [didLog], timeout: 0.5)
    }

    func test_loggerManager_multithreading_delete_and_log_simultaneously() throws {
        let loggerManager = LoggerManager(
            loggers: [],
            applicationCallbackLoggerBundle: nil,
            metaInformationLoggerBundle: nil
        )

        let logCounter = Counter()
        let deleteCounter = Counter()
        let dispatchGroup = DispatchGroup()

        for _ in 1...100 {
            dispatchGroup.enter()
            DispatchQueue.global().async(execute: DispatchWorkItem {
                loggerManager.log("1", onLevel: Level(rawValue: "1"))
                logCounter.increment()
                dispatchGroup.leave()
            })
        }
        for _ in 1...50 {
            dispatchGroup.enter()
            DispatchQueue.global().async(execute: DispatchWorkItem {
                loggerManager.deleteAllLogFiles()
                deleteCounter.increment()
                dispatchGroup.leave()
            })
        }

        switch dispatchGroup.wait(timeout: .now() + 0.6) {
        case .success:
            XCTAssertEqual(logCounter.value(), 100)
            XCTAssertEqual(deleteCounter.value(), 50)

        case .timedOut:
            XCTFail("Timed out waiting for concurrent log and delete operations.")
        }
    }
}

private final class TestLogger: Logging {
    let isAsynchronous: Bool
    var levels: [Level] = Level.allCases
    var loggedMessages: [String] = []

    init(isAsynchronous: Bool) {
        self.isAsynchronous = isAsynchronous
    }

    func log(_ logEntry: LogEntry) {
        loggedMessages.append(logEntry.message.description)
    }
}

private final class BlockingLogger: Logging {
    let isAsynchronous: Bool
    var levels: [Level] = Level.allCases
    private let onLog: () -> Void

    init(isAsynchronous: Bool, onLog: @escaping () -> Void) {
        self.isAsynchronous = isAsynchronous
        self.onLog = onLog
    }

    func log(_ logEntry: LogEntry) {
        onLog()
    }
}
