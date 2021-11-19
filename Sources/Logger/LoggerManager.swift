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
    
    public init(
        loggingConcurrencyMode: LoggingConcurrencyMode = .asyncSerial(.defaultSerialLoggingQueue),
        loggers: [Logging],
        applicationCallbackLoggerBundle: ApplicationCallbackBundle = (callbacks: ApplicationCallbackType.allCases, level: Level.debug),
        metaInformationLoggerBundle: MetaInformationBundle = (types: MetaInformationType.allCases, bundle: Bundle.main, level: Level.debug)
    ) {
        loggers.forEach { $0.configure() }
        self.loggers = loggers

        self.loggingConcurrencyMode = loggingConcurrencyMode

        let applicationCallbackLogger = ApplicationCallbackLogger(
            callbacks: applicationCallbackLoggerBundle.callbacks,
            level: applicationCallbackLoggerBundle.level
        )

        applicationCallbackLogger.messagePublisher
            .sink { [weak self] level, message in
                self?.log(message, onLevel: level)
            }
            .store(in: &subscriptions)

        let metaInformation = metaInformationLoggerBundle.types.dictionary(fromBundle: metaInformationLoggerBundle.bundle)
        log("Meta information: \(metaInformation)", onLevel: metaInformationLoggerBundle.level)
    }

    /// All logs from FileLogger files (represented as `Data`).
    public var perFileLogDataIfAvailable: [URL: Data]? {
        loggingConcurrencyMode.serialQueue.sync {
            loggers
                .compactMap { $0 as? FileLogger }
                .compactMap { $0.perFileLogData }
                .flatMap { $0 }
                .reduce([URL: Data]()) { dictionary, nextElement in
                    var newDictionary = dictionary
                    newDictionary[nextElement.key] = nextElement.value

                    return newDictionary
                }
        }
    }

    public func logFilesRecords(filteredBy filter: (FileLog) -> Bool = { _ in true }) -> [FileLog]? {
        loggers
            .compactMap { $0 as? FileLogger }
            .compactMap { $0.logFilesRecords(filteredBy: filter) }
            .flatMap { $0 }
    }

    /// Method to delete all log files if there are any.
    public func deleteAllLogFilesIfAvailable() {
        loggingConcurrencyMode.serialQueue.async {
            self.loggers.compactMap { $0 as? FileLogger }
                .forEach { try? $0.deleteAllLogFiles() }
        }
    }

    public func log(
        _ message: CustomStringConvertible,
        onLevel level: Level,
        inFile file: String = #file,
        inFunction function: String = #function,
        onLine line: Int = #line
    ) {
        let theFileName = (file as NSString).lastPathComponent
        let logRecord = "\(theFileName) - \(function) - line \(line): \(message)"

        loggingConcurrencyMode.log(toLoggers: self.loggers, message: logRecord, onLevel: level)
    }
}
