//
//  LoggingConcurrencyMode.swift
//  
//
//  Created by Martin Troup on 05.11.2021.
//

import Foundation

/// Logging concurrency types
///
/// - syncSerial: logging executed synchronously towards the main thread. All loggers log serially one by one within a dedicated queue
/// - asyncSerial: logging executed asynchronously towards the main thread. All loggers log serially one by one within a dedicated queue
/// - syncConcurrent: logging executed synchronously towards the main thread. All loggers log concurrently within a dedicated queue
public enum LoggingConcurrencyMode {
    case syncSerial(DispatchQueue)
    case asyncSerial(DispatchQueue)
    case syncConcurrent(serialQueue: DispatchQueue, concurrentQueue: DispatchQueue)

    var serialQueue: DispatchQueue {
        switch self {
        case let .syncSerial(queue):
            return queue
        case let .asyncSerial(queue):
            return queue
        case let .syncConcurrent(serialQueue: queue, _):
            return queue
        }
    }
}

// MARK: - DispatchQueue + default queues

public extension DispatchQueue {
    static let defaultSerialLoggingQueue = DispatchQueue(label: Constants.Queues.serial, qos: .background)
    static let defaultConcurrentLoggingQueue = DispatchQueue(label: Constants.Queues.concurrent, qos: .background, attributes: .concurrent)
}
