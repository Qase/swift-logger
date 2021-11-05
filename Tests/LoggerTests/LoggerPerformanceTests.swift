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
    var logManager: LogManager!

    override func setUp() {
        super.setUp()

        logManager = LogManager(loggingConcurrencyMode: .asyncSerial(.defaultSerialLoggingQueue))
    }

    override func tearDown() {
        logManager = nil

        super.tearDown()
    }

    func test_direct_log() {
        let performanceLogger = PerformanceLogger()

        // This code log directly into logger, where is sleep for 1 second
        // So total run time should be 1s
        self.measure {
            // Put the code you want to measure the time of here.
            performanceLogger.log("Test", onLevel: .info)
        }
    }

    func test_outer_log() {
        let performanceLogger = PerformanceLogger()
        logManager.add(performanceLogger)

        // This code use QLog wrapper over performance logger.
        // So work should be dispatch in special queue without blocking current thread
        self.measure {
            // Put the code you want to measure the time of here.
            logManager.log("Test", onLevel: .info)
        }

        logManager.waitForLogingJobsToFinish()
    }

    func test_thousand_run_NSLog() {
        self.measure {
            for _ in 1...1000 {
                NSLog("Test")
            }
        }
    }

    func test_thousand_run_print() {
        self.measure {
            for _ in 1...1000 {
                print("Test")
            }
        }
    }

    func test_thousand_run_Log_console_async() {
        let consoleLogger = ConsoleLogger()
        consoleLogger.levels = [.info]
        logManager.add(consoleLogger)

        self.measure {
            for _ in 1...1000 {
                logManager.log("Test", onLevel: .info)
            }
        }

        logManager.waitForLogingJobsToFinish()
    }

    func test_thousand_run_Log_file_async() {
        let fileLogger = try! FileLogger()
        fileLogger.levels = [.info]
        logManager.add(fileLogger)

        self.measure {
            for _ in 1...1000 {
                logManager.log("Test", onLevel: .info)
            }
        }

        logManager.waitForLogingJobsToFinish()
    }

    func test_thousand_run_Log_both_async() {
        let fileLogger = try! FileLogger()
        fileLogger.levels = [.info]
        logManager.add(fileLogger)

        let consoleLogger = ConsoleLogger()
        consoleLogger.levels = [.info]
        logManager.add(consoleLogger)

        self.measure {
            for _ in 1...1000 {
                logManager.log("Test", onLevel: .info)
            }
        }

        logManager.waitForLogingJobsToFinish()
    }

    func test_thousand_run_Log_console_sync() {
        let consoleLogger = ConsoleLogger()
        consoleLogger.levels = [.info]
        logManager.add(consoleLogger)

        self.measure {
            for _ in 1...1000 {
                logManager.log("Test", onLevel: .info)
            }
        }
    }

    func test_thousand_run_Log_file_sync() {
        let fileLogger = try! FileLogger()
        fileLogger.levels = [.info]
        logManager.add(fileLogger)

        self.measure {
            for _ in 1...1000 {
                logManager.log("Test", onLevel: .info)
            }
        }
    }

    func test_thousand_run_Log_both_sync() {
        let fileLogger = try! FileLogger()
        fileLogger.levels = [.info]
        logManager.add(fileLogger)

        let consoleLogger = ConsoleLogger()
        consoleLogger.levels = [.info]
        logManager.add(consoleLogger)

        self.measure {
            for _ in 1...1000 {
                logManager.log("Test", onLevel: .info)
            }
        }
    }
}

// MARK: - LogManager + asyncWait

private extension LogManager {
    /// !!! This method only serves for unit tests !!! Before checking values (XCT checks), unit tests must wait for loging jobs to complete.
    /// Loging is being executed on a different queue (logingQueue) and thus here the main queue waits (sync) until all of logingQueue jobs are completed.
    /// Then it executes the block within logingQueue.sync which is empty, so it continues on doing other things.
    func waitForLogingJobsToFinish() {
        loggingConcurrencyMode.serialQueue.sync {
            //
        }
    }
}
