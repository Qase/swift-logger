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
    // Configuration of logging mode
    let loggingConcurrencyMode: LoggingConcurrencyMode
    // Registered loggers
    private let loggers: [Logging]

    private var subscriptions = Set<AnyCancellable>()

    /// `LoggerManager` initialization
    /// - Parameters:
    ///   - loggingConcurrencyMode: concurrency mode in which the manager logs via its registered loggers.
    ///   - loggers: registered loggers.
    ///   - applicationCallbackLoggerBundle: application lifecycle callbacks that are to be logged by the manager.
    ///   - metaInformationLoggerBundle: meta information to be logged by the manager.
    public init(
        loggingConcurrencyMode: LoggingConcurrencyMode = .asyncSerial(.defaultSerialLoggingQueue),
        loggers: [Logging],
        applicationCallbackLoggerBundle: ApplicationCallbackBundle? = (callbacks: ApplicationCallbackType.allCases, level: Level.debug),
        metaInformationLoggerBundle: MetaInformationBundle? = (types: MetaInformationType.allCases, bundle: Bundle.main, level: Level.debug)
    ) {
        loggers.forEach { $0.configure() }
        self.loggers = loggers

        self.loggingConcurrencyMode = loggingConcurrencyMode

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

        if let metaInformationLoggerBundle = metaInformationLoggerBundle {
            let metaInformation = metaInformationLoggerBundle.types.dictionary(fromBundle: metaInformationLoggerBundle.bundle)
            log("Meta information: \(metaInformation)", onLevel: metaInformationLoggerBundle.level)
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
        let logHeader = LogHeader(date: Date(), level: level, dateFormatter: DateFormatter.monthsDaysTimeFormatter)
        let logLocation = LogLocation(fileName: (file as NSString).lastPathComponent, function: function, line: line)

        let log = LogEntry(header: logHeader, location: logLocation, message: message)

        loggingConcurrencyMode.log(toLoggers: self.loggers, log: log)
    }
}
