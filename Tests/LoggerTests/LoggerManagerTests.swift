//
//  LoggerManagerTests.swift
//  
//
//  Created by Martin Ficek on 29.05.2023.
//

import XCTest
@testable import Logger
import Combine

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

        waitForExpectations(timeout: 0.5)
    }

    func test_loggerManager_multithreading_delete_and_log_simultaneously() throws {
        let loggerManager = LoggerManager(
            loggers: .init(),
            applicationCallbackLoggerBundle: nil,
            metaInformationLoggerBundle: nil
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
                            loggerManager.log("1", onLevel: Level(rawValue: "1"))
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
                            loggerManager.deleteAllLogFiles()
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
        
        waitForExpectations(timeout: 0.6)
        XCTAssertEqual(logCount, 100)
        XCTAssertEqual(deleteCount, 50)
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
