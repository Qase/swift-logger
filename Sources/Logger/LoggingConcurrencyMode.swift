//
//  LoggingConcurrencyMode.swift
//  
//
//  Created by Martin Troup on 05.11.2021.
//

import Foundation

/// Logging concurrency
///
/// - asyncSerial: logging executed asynchronously towards the main thread. All loggers log serially one by one within a dedicated queue
public enum LoggingConcurrencyMode {
    case asyncSerial(DispatchQueue)
   
    var serialQueue: DispatchQueue {
        switch self {
        case let .asyncSerial(queue):
            return queue
        }
    }
}

// MARK: - DispatchQueue + default queues

public extension DispatchQueue {
    static let defaultSerialLoggingQueue = DispatchQueue(label: Constants.Queues.serial, qos: .background)
    static let defaultConcurrentLoggingQueue = DispatchQueue(label: Constants.Queues.concurrent, qos: .background, attributes: .concurrent)
}

// MARK: - LoggingConcurrentMode + log

extension LoggingConcurrencyMode {
    func log(toLoggers loggers: [Logging], log: LogEntry) {
        let availableLoggers = loggers.availableLoggers(forLevel: log.header.level)

        switch self {
        case let .asyncSerial(serialQueue):
            serialQueue.async {
                availableLoggers.forEach { $0.log(log) }
            }
        }
    }
}
