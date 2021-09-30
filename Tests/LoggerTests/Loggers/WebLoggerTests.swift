//
//  WebLoggerTests.swift
//  
//
//  Created by Martin Troup on 30.09.2021.
//

import Combine
@testable import Logger
import XCTest

class WebLoggerTests: XCTestCase {

    private var subscriptions: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        subscriptions = Set<AnyCancellable>()
    }

    override func tearDown() {
        subscriptions = nil

        super.tearDown()
    }

    func test_WebLogger_init() {
        let testUUID = UUID()
        let webLogger = WebLogger<DispatchQueue>(
            sessionID: testUUID,
            batchConfiguration: .init(
                maxSize: 10,
                timeWindow: 15,
                queue: .main
            ),
            requestPerformer: { _ in Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
        )

        XCTAssertEqual(webLogger.sessionID, testUUID)
        XCTAssertEqual(webLogger.batchConfiguration.maxSize, 10)
        XCTAssertEqual(webLogger.batchConfiguration.timeWindow, 15)
        XCTAssertEqual(webLogger.batchConfiguration.queue, DispatchQueue.main)

        let expectation = self.expectation(description: "")

        var valueReceived = false

        webLogger.requestPerformer(Data())
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        XCTFail("Unexpected event received - error: \(error).")
                    case .finished:
                        expectation.fulfill()
                    }
                },
                receiveValue: {
                    valueReceived = true
                }
            )
            .store(in: &subscriptions)

        waitForExpectations(timeout: 0.01)
        XCTAssertTrue(valueReceived)
    }

    func test_WebLogger_DispatchQueue_batchConfiguration_default_init() {
        let testUUID = UUID()
        let webLogger = WebLogger<DispatchQueue>(
            sessionID: testUUID,
            requestPerformer: { _ in Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
        )

        XCTAssertEqual(webLogger.sessionID, testUUID)
        XCTAssertEqual(webLogger.batchConfiguration.maxSize, 5)
        XCTAssertEqual(webLogger.batchConfiguration.timeWindow, 4)
        XCTAssertEqual(webLogger.batchConfiguration.queue, .global(qos: .utility))

        let expectation = self.expectation(description: "")

        var valueReceived = false

        webLogger.requestPerformer(Data())
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        XCTFail("Unexpected event received - error: \(error).")
                    case .finished:
                        expectation.fulfill()
                    }
                },
                receiveValue: {
                    valueReceived = true
                }
            )
            .store(in: &subscriptions)

        waitForExpectations(timeout: 0.01)
        XCTAssertTrue(valueReceived)
    }

    func test_batching_by_size() {
        var requestPerformerCount = 0

        let webLogger = WebLogger<DispatchQueue>(
            sessionID: UUID(),
            batchConfiguration: .init(
                maxSize: 10,
                timeWindow: 10,
                queue: .main
            ),
            requestPerformer: { batch in
                XCTAssertEqual((batch as! LogEntryBatch).count, 10)

                return Just(()).setFailureType(to: Error.self)
                    .handleEvents(receiveSubscription: { _ in
                        requestPerformerCount += 1
                    })
                    .eraseToAnyPublisher()
            }
        )

        webLogger.configure()

        (0..<50).forEach { index in
            webLogger.log("random-message-index-\(index)", onLevel: .info)
        }
    }

    func test_batching_by_time() {
        let expectation = self.expectation(description: "")

        let webLogger = WebLogger<DispatchQueue>(
            sessionID: UUID(),
            batchConfiguration: .init(
                maxSize: 10,
                timeWindow: 0.05,
                queue: .main
            ),
            requestPerformer: { batch in
                XCTAssertEqual((batch as! LogEntryBatch).count, 5)

                return Just(()).setFailureType(to: Error.self)
                    .handleEvents(receiveSubscription: { _ in
                        expectation.fulfill()
                    })
                    .eraseToAnyPublisher()
            }
        )

        webLogger.configure()

        (0..<5).forEach { index in
            webLogger.log("random-message-index-\(index)", onLevel: .info)
        }

        waitForExpectations(timeout: 0.1)
    }

    func test_batching_by_size_and_time() {
        let expectation = self.expectation(description: "")

        var requestPerformerCount = 0

        let webLogger = WebLogger<DispatchQueue>(
            sessionID: UUID(),
            batchConfiguration: .init(
                maxSize: 10,
                timeWindow: 0.1,
                queue: .main
            ),
            requestPerformer: { batch in
                switch requestPerformerCount {
                case 0:
                    XCTAssertEqual((batch as! LogEntryBatch).count, 10)
                case 1:
                    XCTAssertEqual((batch as! LogEntryBatch).count, 1)
                case 2:
                    XCTAssertEqual((batch as! LogEntryBatch).count, 5)
                default:
                    ()
                }

                return Just(()).setFailureType(to: Error.self)
                    .handleEvents(receiveSubscription: { _ in
                        requestPerformerCount += 1

                        if requestPerformerCount == 3 {
                            expectation.fulfill()
                        }
                    })
                    .eraseToAnyPublisher()
            }
        )

        webLogger.configure()

        (0..<11).forEach {
            webLogger.log("random-message-index-\($0)", onLevel: .info)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            (0..<5).forEach {
                webLogger.log("random-message-index-\($0)", onLevel: .info)
            }
        }

        waitForExpectations(timeout: 0.2)
    }
}

