//
//  LogManager.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation

/// Global method that handles logging. Once the LogManager is set and all necessary loggers are registered somewhere
/// at the beginning of the application, this method can be called throughout the whole project in order to log.
///
/// - Parameters:
///   - message: String logging message
///   - level: Level of the logging message
///   - file: File where the log function was called
///   - function: Function where the log function was called
///   - line: Line on which the log function was called
public func Log(
    _ message: String,
    onLevel level: Level,
    inFile file: String = #file,
    inFunction function: String = #function,
    onLine line: Int = #line
) {
    LogManager.shared.log(message, onLevel: level, inFile: file, inFunction: function, onLine: line)
}

/// LogManager manages different types of loggers. The class enables to register custom or pre-built loggers.
/// Each of these logger classes must be subclassed from BaseLogger. The class handles logging to registered loggers
/// based on levels they are set to acccept.
public class LogManager {

    // The class is used as a Singleton, thus should be accesed via instance property !!!
    public static let shared = LogManager()

    private var loggers: [Logging]

    // Configuration of logging mode
    public var loggingConcurrencyMode: LoggingConcurrencyMode

    public var fileLoggerIfPresent: FileLogger? {
        loggers.compactMap { $0 as? FileLogger}.first
    }

    private let applicationCallbackLogger = ApplicationCallbackLogger()
    private let metaInformationLogger = MetaInformationLogger()

    init(loggingConcurrencyMode: LoggingConcurrencyMode = .asyncSerial(.defaultSerialLoggingQueue)) {
        self.loggingConcurrencyMode = loggingConcurrencyMode

        loggers = [Logging]()

        applicationCallbackLogger.delegate = self
        metaInformationLogger.delegate = self
    }

    /// Method to return a specific logger if registered to the Log manager.
    ///
    /// - Returns: the logger if exists, nil otherwise
    public func logger<T: Logging>() -> T? {
        loggers.compactMap { $0 as? T }.first
    }

    /// Method to register a new custom or pre-build logger.
    ///
    /// - Parameter logger: Logger to be registered
    /// - Returns: if adding succeds or not
    @discardableResult
    public func add<T: Logging>(_ logger: T) -> Bool {
        if loggers.contains(where: { $0 is T }) {
            Log(
                "LogManager does not support having multiple logger of the same type, such as two instances of FileLogger.",
                onLevel: .error
            )
            return false
        }

        logger.configure()
        loggers.append(logger)
        return true
    }

    /// Method to remove a specific logger registered to the Log manager.
    ///
    /// - Parameter logger: to be removed
    public func remove<T: Logging>(_ logger: T) {
        loggers.removeAll { $0 is T }
    }

    /// Method to remove all existing loggers registered to the Log manager.
    public func removeAllLoggers() {
        loggers = [Logging]()
    }

    /// Method to handle logging, it is called internaly via global method Log(_, _) and thus its not visible outside
    /// of the module.
    ///
    /// - Parameters:
    ///   - message: String logging message
    ///   - level: Level of the logging message
    ///   - file: File where the log function was called
    ///   - function: Function where the log function was called
    ///   - line: Line on which the log function was called
    func log(
        _ message: String,
        onLevel level: Level,
        inFile file: String = #file,
        inFunction function: String = #function,
        onLine line: Int = #line
    ) {
        let theFileName = (file as NSString).lastPathComponent
        let logRecord = "\(theFileName) - \(function) - line \(line): \(message)"

        switch loggingConcurrencyMode {
        case let .syncSerial(queue):
            logSyncSerially(onQueue: queue, logRecord, onLevel: level)
        case let .asyncSerial(queue):
            logAsyncSerially(onQueue: queue, logRecord, onLevel: level)
        case let .syncConcurrent(serialQueue: serialQueue, concurrentQueue: concurrentQueue):
            logSyncConcurrently(serialQueue: serialQueue, concurrentQueue: concurrentQueue, logRecord, onLevel: level)
        }
    }

    /// Method to delete all log files if there are any.
    public func deleteAllLogFiles() {
        loggingConcurrencyMode.serialQueue.async {
            dispatchPrecondition(condition: .onQueue(self.loggingConcurrencyMode.serialQueue))

            self.loggers.compactMap { $0 as? FileLogger }
                .forEach { try? $0.deleteAllLogFiles() }
        }
    }

    /// Method to export all log files if there are any.
     public func exportLogFiles() -> [URL] {
         loggingConcurrencyMode.serialQueue.sync {
             dispatchPrecondition(condition: .onQueue(self.loggingConcurrencyMode.serialQueue))

            return self.loggers
                .compactMap { $0 as? FileLogger }
                .compactMap { $0.getArchivedLogFilesUrl() }
        }
     }

    /// Method to set specific application's callbacks to be logged and a level to be logged on.
    /// If array of callbacks set nil, none of the application's callbacks will be logged.
    /// If array of callbacks set an emty array, all of the application's callbacks will be logged.
    ///
    /// - Parameters:
    ///   - callbacks: array of application's callbacks to be logged
    ///   - level: to be logged on
    public func setApplicationCallbackLogger(with callbacks: [ApplicationCallbackType]?, onLevel level: Level) {
        setApplicationCallbackLogger(with: callbacks)
        setApplicationCallbackLogger(onLevel: level)
    }

    /// Method to set specific application's callbacks to be logged.
    /// If array of callbacks set nil, none of the application's callbacks will be logged.
    /// If array of callbacks set an emty array, all of the application's callbacks will be logged.
    ///
    /// - Parameters:
    ///   - callbacks: array of application's callbacks to be logged
    public func setApplicationCallbackLogger(with callbacks: [ApplicationCallbackType]?) {
        applicationCallbackLogger.callbacks = callbacks
    }

    /// Method to set a level on which application's callbacks should be logged.
    ///
    /// - Parameter level: to be logged on
    public func setApplicationCallbackLogger(onLevel level: Level) {
        applicationCallbackLogger.level = level
    }

    /// Method to log specific meta information.
    ///
    /// - Parameters:
    ///   - dataToLog: array of meta information to be logged, all meta information is logged when the array set empty
    ///   - level: to be logged on
    public func logMetaInformation(_ dataToLog: [MetaInformationType] = [], onLevel level: Level) {
        metaInformationLogger.log(dataToLog, onLevel: level)
    }

    /// Method to log synchronously towards the main thread. All loggers log serially one by one within a dedicated queue.
    ///
    /// - Parameters:
    ///   - message: to be logged
    ///   - level: to be logged on
    private func logSyncSerially(onQueue queue: DispatchQueue, _ message: String, onLevel level: Level) {
        queue.sync {
            dispatchPrecondition(condition: .onQueue(queue))

            guard !loggers.isEmpty else {
                assertionFailure("No loggers were added to the LogManager.")
                return
            }

            self.loggers
                .filter { $0.doesLog(forLevel: level) }
                .forEach { $0.log(message, onLevel: level) }
        }
    }

    /// Method to log asynchronously towards the main thread. All loggers log serially one by one within a dedicated queue.
    ///
    /// - Parameters:
    ///   - message: to be logged
    ///   - level: to be logged on
    private func logAsyncSerially(onQueue queue: DispatchQueue, _ message: String, onLevel level: Level) {
        queue.async {
            dispatchPrecondition(condition: .onQueue(queue))

            guard !self.loggers.isEmpty else {
                assertionFailure("No loggers were added to the LogManager.")
                return
            }

            self.loggers
                .filter { $0.doesLog(forLevel: level) }
                .forEach { $0.log(message, onLevel: level) }
        }
    }

    /// Method to log synchronously towards the main thread. All loggers log concurrently within a dedicated queue.
    ///
    /// - Parameters:
    ///   - message: to be logged
    ///   - level: to be logged on
    private func logSyncConcurrently(serialQueue: DispatchQueue, concurrentQueue: DispatchQueue, _ message: String, onLevel level: Level) {
        serialQueue.sync {
            dispatchPrecondition(condition: .onQueue(serialQueue))

            guard !loggers.isEmpty else {
                assertionFailure("No loggers were added to the LogManager.")
                return
            }

            loggers
                .filter { $0.doesLog(forLevel: level) }
                .forEach { logger in
                    concurrentQueue.async {
                        logger.log(message, onLevel: level)
                    }
                }
        }
    }
}

// MARK: - ApplicationCallbackLoggerDelegate methods implementation
extension LogManager: ApplicationCallbackLoggerDelegate {
    func logApplicationCallback(_ message: String, onLevel level: Level) {
        log(message, onLevel: level)
    }
}

// MARK: - MetaInformationLoggerDelegate methods implementation
extension LogManager: MetaInformationLoggerDelegate {
    func logMetaInformation(_ message: String, onLevel level: Level) {
        log(message, onLevel: level)
    }
}
