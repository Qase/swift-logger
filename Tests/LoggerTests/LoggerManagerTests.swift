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
    func test_loggerManager_multithreading_delete_and_log_simultaneously() throws {
        let loggerManager = LoggerManager(loggers: .init())
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
