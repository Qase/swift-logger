//
//  LoggerManager.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Combine
import Foundation

public typealias ApplicationCallbackBundle = (callbacks: [ApplicationCallbackType], level: Level)
public typealias MetaInformationBundle = (types: [MetaInformationType], bundle: Bundle, level: Level)

/// LoggerManager manages different types of loggers. The class enables to register custom or pre-built loggers.
/// Each of these logger classes must be subclassed from BaseLogger. The class handles logging to registered loggers
/// based on levels they are set to acccept.
public class LoggerManager {
    // Async loggers are processed serially on a background queue.
    let serialQueue: DispatchQueue = .defaultSerialLoggingQueue
    // Registered loggers
    private let loggers: [Logging]

    private let metaInformationBundle: MetaInformationBundle?
    private var dateOfLastLog: Date?

    private var subscriptions = Set<AnyCancellable>()

    /// `LoggerManager` initialization
    /// - Parameters:
    ///   - loggers: registered loggers.
    ///   - applicationCallbackLoggerBundle: application lifecycle callbacks that are to be logged by the manager.
    ///   - metaInformationLoggerBundle: meta information to be logged by the manager.
    public init(
        loggers: [Logging],
        applicationCallbackLoggerBundle: ApplicationCallbackBundle? = (callbacks: ApplicationCallbackType.allCases, level: Level.debug),
        metaInformationLoggerBundle: MetaInformationBundle? = (types: MetaInformationType.allCases, bundle: Bundle.main, level: Level.debug)
    ) {
        loggers.forEach { $0.configure() }
        self.loggers = loggers
        self.metaInformationBundle = metaInformationLoggerBundle

        if let applicationCallbackLoggerBundle = applicationCallbackLoggerBundle {
            let applicationCallbackLogger = ApplicationCallbackLogger(
                callbacks: applicationCallbackLoggerBundle.callbacks,
                level: applicationCallbackLoggerBundle.level
            )

            applicationCallbackLogger.messagePublisher
                .sink { [weak self] level, message in
                    self?.log(message, onLevel: level)
                }
                .store(in: &subscriptions)
        }
    }

    /// Log specific entity via the manager.
    /// - Parameters:
    ///   - message: Entity to be logged.
    ///   - file: Name of the file where the logging occures.
    ///   - function: Name of the function where the logging occures.
    ///   - line: Number of the line where the logging occures.
    public func log(
        _ message: CustomStringConvertible,
        onLevel level: Level,
        inFile file: String = #file,
        inFunction function: String = #function,
        onLine line: Int = #line
    ) {
        let currentDate = Date()
        let logHeader = LogHeader(date: currentDate, level: level, dateFormatter: DateFormatter.monthsDaysTimeFormatter)
        let logLocation = LogLocation(fileName: (file as NSString).lastPathComponent, function: function, line: line)
        let log = LogEntry(header: logHeader, location: logLocation, message: message)
        let availableLoggers = loggers.availableLoggers(forLevel: log.header.level)

        if !Calendar.current.isDate(currentDate, inSameDayAs: dateOfLastLog ?? .distantPast) {
            dateOfLastLog = currentDate
            logMetaInformation()
        }

        let synchronousLoggers = availableLoggers.filter { !$0.isAsynchronous }
        synchronousLoggers.forEach { $0.log(log) }

        let asynchronousLoggers = availableLoggers.filter(\.isAsynchronous)
        guard !asynchronousLoggers.isEmpty else { return }

        serialQueue.async {
            asynchronousLoggers.forEach { $0.log(log) }
        }
    }

    public func logMetaInformation() {
        guard let metaInformationBundle else { return }

        let metaInformation = metaInformationBundle.types.dictionary(fromBundle: metaInformationBundle.bundle)
        log("Meta information: \(metaInformation)", onLevel: metaInformationBundle.level)
    }

    public func deleteAllLogFiles() {
        loggers.compactMap { $0 as? FileLogger }
            .forEach { $0.deleteAllLogFiles() }
        dateOfLastLog = nil
    }
}

// MARK: - DispatchQueue + default queue

private extension DispatchQueue {
    static let defaultSerialLoggingQueue = DispatchQueue(label: Constants.Queues.serial, qos: .background)
}
