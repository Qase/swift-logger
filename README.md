# Logger

Logger is a super lightweight logging library for iOS development in Swift. It provides a few pre-built loggers including native os_log or a file logger. It also provides an interface for creating custom loggers.

## Requirements

- Swift 5.0+
- Xcode 10+
- iOS 14.0+ 
- MacOS 11.0+

## Usage

### Logging levels

It is possible to log on different levels. Each logger can support different levels, meaning that it records only log messages on such levels. For example multiple loggers of the same type can be set to support different levels and thus separate logging on such level. Another use case is to further filter messages of specific type declared by its level. 

Although it is definitely up to the developer in which way the levels will be used, there is a recommended way how to use them since each of them serves a different purpose.


- `info` for mostly UI related user actions
- `debug` for debugging purposes
- `verbose` for extended debug purposes, especially when there is a need for very specific messages
- `warn` for warnings
- `error` for errors
- `system` (for native os_log only) matches to os_log_fault -> sends a fault-level message to the logging system
- `process` (for native os_log only) matches to os_log_error -> sends an error-level message to the logging system
- `custom(CustomStringConvertible)` available for other level customization if necessary

### Pre-build loggers

#### `ConsoleLogger`
The simplest logger. Wraps `print(_:separator:terminator:)` function from Swift Standard Library.

#### `SystemLogger`
Wraps the native ```OSLog``` to log messages on the system level.

#### `FileLogger`

Enables logging to a file. Each log file relates to a single day data. Another day, another log file is used. `numberOfLogFiles` specifies the number of log files that are stored. In other words, how many days back (log files) should be kept. If the last log file is filled, the first one gets overriden using the simplest Round-robin strategy.

#### `WebLogger`

Enables logging via REST API to a target server. To reduce the traffic, logs are grouped into so-called batches when sent. A user can set the max size of such batches and also a max time interval between individual batches being sent. 


The integrator is responsible for the creation of `URLRequest` with the log batches & firing the request.
Target server that receives logs is independent on the `WebLogger`. Thus the integrator is responsible for the implementation of a target server. The target server is to receive / parse / display the incoming log batches. If the does not wish to implement a customized server, we also provide [a simple server solution](https://github.com/Qase/LoggingServer/) written in Node.js.

Here is an example of log batch in JSON:
```
[
 {"severity": "VERBOSE",
  "sessionName": "E598B4C1-2B08-4563-81C0-2A77E5CE0C3C",
  "message":"/some/path/LoggerTests.swift - testWebLogger() - line 165: Test verbose",
  "timestamp": 1529668897318.845},
 {"severity": "INFO",
  "sessionName":"E598B4C1-2B08-4563-81C0-2A77E5CE0C3C",
  "message": "/some/path/LoggerTests.swift - testWebLogger() - line 166: Test system",
  "timestamp":1529668897319.6549},
 {"severity":"INFO",
  "sessionName":"E598B4C1-2B08-4563-81C0-2A77E5CE0C3C",
  "message":"/some/path/LoggerTests.swift - testWebLogger() - line 167: Test process",
  "timestamp":1529668897319.6959}
]
```


Here is the set of properties a user can customize:
  - `sessionID` which can be used on a server to filter logs for a specific application instance
  - `batchConfiguration` max batch size & time interval of batches

#### `ApplicationCallbackLogger`

A special type of logger, that automatically logs all received UIApplication<callback> notifications, further called application callbacks. Here is a complete list of supported application callbacks:
  - `UIApplicationWillTerminate`
  - `UIApplicationDidBecomeActive`
  - `UIApplicationWillResignActive`
  - `UIApplicationDidEnterBackground`
  - `UIApplicationDidFinishLaunching`
  - `UIApplicationWillEnterForeground`
  - `UIApplicationSignificantTimeChange`
  - `UIApplicationUserDidTakeScreenshot`
  - `UIApplicationDidChangeStatusBarFrame`
  - `UIApplicationDidReceiveMemoryWarning`  
  - `UIApplicationWillChangeStatusBarFrame`
  - `UIApplicationDidChangeStatusBarOrientation`
  - `UIApplicationWillChangeStatusBarOrientation`
  - `UIApplicationProtectedDataDidBecomeAvailable`
  - `UIApplicationBackgroundRefreshStatusDidChange`
  - `UIApplicationProtectedDataWillBecomeUnavailable`  
  
The logger is integrated and set automatically, thus it logs all application callbacks on `debug` level. By using `applicationCallbackLoggerBundle` parameter when initializing `LoggerManager`, a user can set specific application callbacks to be logged (all of them are logged by default). If an empty array of callbacks is passed, none of application callbacks will be logged.

#### `MetaInformationLogger`

A special type of logger, that enables to log various meta information about the application and the host application. Here is a complete list of supported meta information:

  - `identifier` application unique identifier
  - `compiler` used compiler version
  - `version` CFBundleShortVersionString a.k.a. version of the application
  - `buildNumber` CFBundleVersion a.k.a. build number of the application
  - `modelType` model of the application's host device
  - `currentOSVersion` current OS version of the application's host device
  - `upTime` boot time of the application
  - `language` localization of the application's host device

The logger is integrated and set automatically, thus it logs all application information on `debug` level. By using `metaInformationLoggerBundle` parameter when initializing `LoggerManager`, a user can set specific information to be logged (all is logged by default). If an empty array of types (meta information) is passed, none of application information will be logged.

### Creating custom loggers

There is a possibility of creating custom loggers just by implementing `Logging` protocol. In the simplest form, the custom logger only needs to implement `log(_:onLevel:)` and `levels()` methods. Optionaly it can also implement `configure()` method in case there is some configuration necessary before starting logging.

Here is an example of a custom logger that enables logging to Crashlytics:
```
import Fabric
import Crashlytics

class CrashLyticsLogger: Logger.Logging {
    open func configure() {
        Fabric.with([Crashlytics.self])
    }
    
    open func log(_ message: String, onLevel level: Level) {
        CLSLogv("%@", getVaList(["[\(level.rawValue) \(Date().toFullDateTimeString())] \(message)"]))
    }

    open func levels() -> [Level] {
        return [.verbose, .info, .debug, .warn, .error]
    }

}
```

### Initialization

Logging initialization is done through `LoggerManager` instance. The LoggerManager holds an array of all configured loggers and then manages the logging.

Here is an example of how to initialize the logger to use `FileLogger`, `ConsoleLogger` and previously created custom `CrashLyticsLogger`:

```

let fileLogger = FileLogger()
fileLogger.levels = [.warn, .error]

let systemLogger = ConsoleLogger()
systemLogger.levels = [.verbose, .info, .debug, .warn, .error]

let crashlyticsLogger = CrashLyticsLogger()

let loggerManager = LoggerManager(loggers: [fileLogger, systemLogger, crashlyticsLogger])
```

#### Global function

Logger can be made available through the whole application if a global function is implemented. Here is an example of such function:

```
//
// - Parameters:
//   - message: String logging message
//   - level: Level of the logging message
//   - file: File where the log function was called
//   - function: Function where the log function was called
//   - line: Line on which the log function was called
public func Log(
    _ message: String,
    onLevel level: Level,
    inFile file: String = #file,
    inFunction function: String = #function,
    onLine line: Int = #line
) {
    loggerManager.log(message, onLevel: level, inFile: file, inFunction: function, onLine: line)
}
```

### Logging

Logging is done using a simple `Log(_:onLevel)` macro function. Such function can be used anywhere, where `Logger` is imported. 

Example of how to log:
```
Log("This is the message to be logged.", onLevel: .info)
```

### Logging execution

`LoggerManager` has its own style of executing tasks. It's done in form of `asyncSerial` mode, that works on background thread without disrupting the main thread.

#### `asyncSerial`

Logging task is dispatched asynchronously on a custom serial queue, where all loggers perform their tasks serially one by one.

![asyncserial](https://user-images.githubusercontent.com/2511209/33495945-a2732168-d6c8-11e7-9a77-519204be448a.png)

### Sending file logs via mail

The framework provides `SendMailView` that has a pre-configured SwiftUI `View` that, when presented, will offer the option to send all log files via mail.

### Displaying file logs in `FileLogsTable`

The framework provides an example of `SwiftUI` `View` called `FileLogsTable`. It displays all log records stored via `FileLogger` in a table view.  
The `View` is available within `SwiftLoggerSampleApp`.

## License

`Logger` is released under the [MIT License](LICENSE).

