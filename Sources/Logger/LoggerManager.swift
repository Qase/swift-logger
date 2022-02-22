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

    /// Get a specific registered logger from the manager.
    /// - Parameter id: unique identifier of the logger.
    public func logger(withId id: UUID) -> Logging? {
      loggers.first { $0.id == id }
    }

    /// `LoggerManager` initialization
    /// - Parameters:
    ///   - loggingConcurrencyMode: concurrency mode in which the manager logs via its registered loggers.
    ///   - loggers: registered loggers.
    ///   - applicationCallbackLoggerBundle: application lifecycle callbacks that are to be logged by the manager.
    ///   - metaInformationLoggerBundle: meta information to be logged by the manager.
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


    /// All logged data from `FileLogger` in a form of `[URL: Data]`. `URL` represents a specific log file while `Data` is the content of the file.
    /// NOTE: This function returns any data only if at least one `FileLogger` is registed within the manager.
    /// - Parameter loggerId: ID of a specific `FileLogger` instance if more are registed. If not specified, all files from all `FileLogger` instances are to be returned.
    public func perFileLogDataIfAvailable(forLoggerWithId loggerId: UUID? = nil) -> [URL: Data]? {
        loggingConcurrencyMode.serialQueue.sync {
            (loggerId.flatMap(logger(withId:)).map { [$0] } ?? loggers)
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

    /// All logged data from `FileLogger` in a form of `FileLogEntry` array. `FileLogEntry` represents a single well structured log entry from a `FileLogger`.
    /// NOTE: This function returns any data only if at least one `FileLogger` is registed within the manager.
    /// - Parameters:
    ///   - loggerId: ID of a specific `FileLogger` instance if more are registed. If not specified, all log entries from all `FileLogger` instances are to be returned.
    ///   - filter: Additional filter can be applied to specify what entries are to be returned.
    public func logFilesRecords(
      forLoggerWithId loggerId: UUID? = nil,
      filteredBy filter: (FileLogEntry) -> Bool = { _ in true }
    ) -> [FileLogEntry]? {
        (loggerId.flatMap(logger(withId:)).map { [$0] } ?? loggers)
            .compactMap { $0 as? FileLogger }
            .compactMap { $0.logFilesRecords(filteredBy: filter) }
            .flatMap { $0 }
    }


    /// Delete all log files created by an instance of `FileLogger`.
    /// NOTE: This function returns any data only if at least one `FileLogger` is registed within the manager.
    /// - Parameters:
    ///   - loggerId: ID of a specific `FileLogger` instance if more are registed. If not specified, all files from all `FileLogger` instances are to be deleted.
    public func deleteAllLogFilesIfAvailable(forLoggerWithId loggerId: UUID? = nil) {
        loggingConcurrencyMode.serialQueue.async {
            (loggerId.flatMap(self.logger(withId:)).map { [$0] } ?? self.loggers)
                .compactMap { $0 as? FileLogger }
                .forEach { try? $0.deleteAllLogFiles() }
        }
    }

    /// Get `URL` with archived log files bundle for a single `FileLogger`.
    /// NOTE: This function returns any data only if at least one `FileLogger` is registed within the manager.
    /// - Parameters:
    ///   - loggerId: ID of a specific `FileLogger` instance if more are registed. If not specified, the archive for the first found `FileLogger` instance will be returned.
    ///   - fileName: Name of the archived file.
    public func getArchivedLogFilesUrl(
        forLoggerWithId loggerId: UUID? = nil,
        withFileName fileName: String? = nil
    ) -> URL? {
        let fileLoggerById = loggerId.flatMap(self.logger(withId:)).flatMap { $0 as? FileLogger }

        return (fileLoggerById ?? self.loggers.compactMap { $0 as? FileLogger }.first)?
            .getArchivedLogFilesUrl(withFileName: fileName)
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
