import Foundation
import Logger

class DemoLogger {
    let loggerManager: LoggerManager
    let fileLogger: FileLogger?

    init(category: String) {
        let fileLogger = try? FileLogger(
            sharingConfiguration: .nonShared(maxNumberOfFiles: 7),
            lineSeparator: "\n"
        )
        fileLogger?.levels = Logger.Level.allCases
        self.fileLogger = fileLogger

        let unifiedLogger = NativeLogger(
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "---",
            category: category
        )

        let loggers: [Logger.Logging?] = [fileLogger, unifiedLogger]

        self.loggerManager = LoggerManager(loggers: loggers.compactMap { $0 })
    }

    public func log(
        _ message: String,
        onLevel level: Level,
        inFile file: String = #file,
        inFunction function: String = #function,
        onLine line: Int = #line
    ) {
        loggerManager.log(
            message,
            onLevel: Logger.Level(rawValue: level.rawValue),
            inFile: file,
            inFunction: function,
            onLine: line
        )
    }
}

private let logger = DemoLogger(category: "swift-logger")
var fileLogger: FileLogger? {
    logger.fileLogger
}

func log(
    _ message: String,
    onLevel level: Level = .default,
    inFile file: String = #file,
    inFunction function: String = #function,
    onLine line: Int = #line
) {
    logger.log(
        message,
        onLevel: level,
        inFile: file,
        inFunction: function,
        onLine: line
    )
}
