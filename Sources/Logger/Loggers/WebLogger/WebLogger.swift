//
//  WebLogger.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

// TODO: Cover with unit tests

import Foundation
import Combine

public struct BatchConfiguration<S: Scheduler> {
    // Maximum size of a batch (a bag of logs) which is sent to a server
    let maxSize: Int
    // Maximum time window after which a batch (a bag of logs) is sent to a server
    let timeWindow: S.SchedulerTimeType.Stride
    // Queue on which batches (bags of logs) are being collected
    let queue: S

    public init(
        maxSize: Int,
        timeWindow: S.SchedulerTimeType.Stride,
        queue: S
    ) {
        self.maxSize = maxSize
        self.timeWindow = timeWindow
        self.queue = queue
    }
}

public class WebLogger<S: Scheduler>: Logging {

    // `sessionID` is used on a server to filter logs for a specific application instance.
    // - each application may provide or is provided with a `sessionID`
    // - `sessionID` may be persisted or renewed after each application run (implementation responsibility of `WebLogger` integrator)
    let sessionID: UUID
    // Configuration for batching individual logs (time, size & queue on which the batching happens).
    let batchConfiguration: BatchConfiguration<S>
    // A function that is handling the log batch server sending.
    // - passed is the log batch as an `Encodable` instance
    // - returning `Void` if the request happens successfully, an instance of `Error` otherwise
    // - the caller is responsible for creating & firing an instance of `URLRequest`. The `URLRequest` needs to attach
    // the log batch (`Decodable` instance) passed in as a parameter
    let requestPerformer: (Encodable) -> AnyPublisher<Void, Error>

    private let logSubject = PassthroughSubject<WebLog, Never>()
    private var subscriptions = Set<AnyCancellable>()

    public var levels: [Level] = [.info]

    /// `WebLogger` enables to configure and send logs to a specific server.
    /// The integrator is responsible for providing a running server, that is able to receive the log batch and present it.
    /// - Parameters:
    ///   - sessionID: can be used on a server to filter logs for a specific application instance
    ///   - batchConfiguration: configuration for batching individual logs
    ///   - requestPerformer: a function that is handling the log batch server sending
    public init(
        sessionID: UUID = UUID(),
        batchConfiguration: BatchConfiguration<S>,
        requestPerformer: @escaping (Encodable) -> AnyPublisher<Void, Error>
    ) {
        self.sessionID = sessionID
        self.batchConfiguration = batchConfiguration
        self.requestPerformer = requestPerformer
    }

    public func configure() {
        logSubject
            .collect(.byTimeOrCount(batchConfiguration.queue, batchConfiguration.timeWindow, batchConfiguration.maxSize))
            .filter { $0.count > 0 }
            .flatMap { [weak self] logsBatch -> AnyPublisher<Void, Never> in
                guard let self = self else {
                    print("WebLogger is nil while trying to reach it within a closure!")

                    return Empty<Void, Never>().eraseToAnyPublisher()
                }

                return self.requestPerformer(logsBatch)
                    .catch { error -> Empty<Void, Never> in
                        print("[WebLogger] Failing to send logs to a server with error: \(error)!")

                        return Empty<Void, Never>()
                    }
                    .eraseToAnyPublisher()
            }
            .sink(receiveValue: { _ in })
            .store(in: &subscriptions)
    }

    public func log(_ message: CustomStringConvertible, onLevel level: Level) {
        let entry = WebLog(
            level: level,
            timestamp: Date().timeIntervalSince1970 * 1000,
            message: message,
            sessionID: sessionID
        )

        logSubject.send(entry)
    }
}

// MARK: - Default init for `WebLogger<DispatchQueue>`

extension WebLogger where S == DispatchQueue {
    public convenience init(
        sessionID: UUID = UUID(),
        requestPerformer: @escaping (Encodable) -> AnyPublisher<Void, Error>
    ) {
        self.init(
            sessionID: sessionID,
            batchConfiguration: .init(maxSize: 5, timeWindow: 4, queue: .global(qos: .utility)),
            requestPerformer: requestPerformer
        )
    }
}
