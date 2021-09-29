//
//  PerformanceLogger.swift
//
//
//  Created by Martin Troup on 24.09.2021.
//

@testable import Logger
import XCTest

// Custom logger for performance testing
class PerformanceLogger: Logger.Logging {
    open func configure() {
        //
    }
    open func log(_ message: String, onLevel level: Level) {
        sleep(1)
    }

    var levels: [Level] = [.verbose, .info, .debug, .warn, .error]
}

class LoggerPerformanceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // Set Console logger and File logger
        let logManager = LogManager.shared
        logManager.removeAllLoggers()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_direct_log() {

        let performanceLogger = PerformanceLogger()
        _ = LogManager.shared.add(performanceLogger)

        // This code log directly into logger, where is sleep for 1 second
        // So total run time should be 1s
        self.measure {
            // Put the code you want to measure the time of here.
            performanceLogger.log("Test", onLevel: .info)
        }
    }

    func test_outer_log() {

        let performanceLogger = PerformanceLogger()
        _ = LogManager.shared.add(performanceLogger)

        // This code use QLog wrapper over performance logger.
        // So work should be dispatch in special queue without blocking current thread
        self.measure {
            // Put the code you want to measure the time of here.
            Log("Test", onLevel: .info)
        }

        LogManager.shared.waitForLogingJobsToFinish()
    }

    func test_thousand_run_NSLog() {
        let performanceLogger = PerformanceLogger()
        _ = LogManager.shared.add(performanceLogger)

        self.measure {
            for _ in 1...1000 {
                NSLog("Test")
            }
        }
    }

    func test_thousand_run_print() {
        let performanceLogger = PerformanceLogger()
        _ = LogManager.shared.add(performanceLogger)

        self.measure {
            for _ in 1...1000 {
                print("Test")
            }
        }
    }

    func test_thousand_run_Log_console_async() {
        let consoleLogger = ConsoleLogger()
        consoleLogger.levels = [.info]
        _ = LogManager.shared.add(consoleLogger)

        self.measure {
            for _ in 1...1000 {
                Log("Test", onLevel: .info)
            }
        }

        LogManager.shared.waitForLogingJobsToFinish()
    }

    func test_thousand_run_Log_file_async() {
        let fileLogger = FileLogger()
        fileLogger.levels = [.info]
        _ = LogManager.shared.add(fileLogger)

        self.measure {
            for _ in 1...1000 {
                Log("Test", onLevel: .info)
            }
        }

        LogManager.shared.waitForLogingJobsToFinish()
    }

    func test_thousand_run_Log_both_async() {
        LogManager.shared.loggingConcurrencyMode = .asyncSerial

        let fileLogger = FileLogger()
        fileLogger.levels = [.info]
        _ = LogManager.shared.add(fileLogger)

        let consoleLogger = ConsoleLogger()
        consoleLogger.levels = [.info]
        _ = LogManager.shared.add(consoleLogger)

        self.measure {
            for _ in 1...1000 {
                Log("Test", onLevel: .info)
            }
        }

        LogManager.shared.waitForLogingJobsToFinish()
    }

    func test_thousand_run_Log_console_sync() {
        LogManager.shared.loggingConcurrencyMode = .syncSerial

        let consoleLogger = ConsoleLogger()
        consoleLogger.levels = [.info]
        _ = LogManager.shared.add(consoleLogger)

        self.measure {
            for _ in 1...1000 {
                Log("Test", onLevel: .info)
            }
        }
    }

    func test_thousand_run_Log_file_sync() {
        LogManager.shared.loggingConcurrencyMode = .syncSerial

        let fileLogger = FileLogger()
        fileLogger.levels = [.info]
        _ = LogManager.shared.add(fileLogger)

        self.measure {
            for _ in 1...1000 {
                Log("Test", onLevel: .info)
            }
        }
    }

    func test_thousand_run_Log_both_sync() {
        LogManager.shared.loggingConcurrencyMode = .syncSerial

        let fileLogger = FileLogger()
        fileLogger.levels = [.info]
        _ = LogManager.shared.add(fileLogger)

        let consoleLogger = ConsoleLogger()
        consoleLogger.levels = [.info]
        _ = LogManager.shared.add(consoleLogger)

        self.measure {
            for _ in 1...1000 {
                Log("Test", onLevel: .info)
            }
        }
    }
}
