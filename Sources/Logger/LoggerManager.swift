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

    public func logger(withID id: UUID) -> Logging? {
      loggers.first { $0.id == id }
    }
    
    public init(
        loggingConcurrencyMode: LoggingConcurrencyMode = .asyncSerial(.defaultSerialLoggingQueue),
        loggers: [Logging],
        applicationCallbackLoggerBundle: ApplicationCallbackBundle = (callbacks: [], level: Level.debug),
        metaInformationLoggerBundle: MetaInformationBundle = (types: [], bundle: Bundle.main, level: Level.debug)
    ) {
        loggers.forEach { $0.configure() }
        self.loggers = loggers

        self.loggingConcurrencyMode = loggingConcurrencyMode

        if applicationCallbackLoggerBundle.callbacks.count > 0 {
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

        if metaInformationLoggerBundle.types.count > 0 {
            let metaInformation = metaInformationLoggerBundle.types.dictionary(fromBundle: metaInformationLoggerBundle.bundle)
            log("Meta information: \(metaInformation)", onLevel: metaInformationLoggerBundle.level)
        }
    }

    /// All logs from FileLogger files (represented as `Data`).
    public func perFileLogDataIfAvailable(forLoggerWithID loggerID: UUID? = nil) -> [URL: Data]? {
        loggingConcurrencyMode.serialQueue.sync {
            (loggerID.flatMap(logger(withID:)).map { [$0] } ?? loggers)
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

    public func logFilesRecords(
      forLoggerWithID loggerID: UUID? = nil,
      filteredBy filter: (FileLogEntry) -> Bool = { _ in true }
    ) -> [FileLogEntry]? {
        (loggerID.flatMap(logger(withID:)).map { [$0] } ?? loggers)
            .compactMap { $0 as? FileLogger }
            .compactMap { $0.logFilesRecords(filteredBy: filter) }
            .flatMap { $0 }
    }

    /// Method to delete all log files if there are any.
    public func deleteAllLogFilesIfAvailable(forLoggerWithID loggerID: UUID? = nil) {
        loggingConcurrencyMode.serialQueue.async {
            (loggerID.flatMap(self.logger(withID:)).map { [$0] } ?? self.loggers)
                .compactMap { $0 as? FileLogger }
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
        let logHeader = LogHeader(date: Date(), level: level, dateFormatter: DateFormatter.monthsDaysTimeFormatter)
        let logLocation = LogLocation(fileName: (file as NSString).lastPathComponent, function: function, line: line)

        let log = LogEntry(header: logHeader, location: logLocation, message: message)

        loggingConcurrencyMode.log(toLoggers: self.loggers, log: log)
    }
}
