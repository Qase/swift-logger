# Logger

Logger is a super lightweight logging library for iOS development in Swift. It provides a few pre-built loggers including native os_log or a file logger. It also provides an interface for creating custom loggers.

## Requirements

- Swift 5.0+
- Xcode 14.0+
- iOS 15.0+ 
- MacOS 12.0+
- WatchOS 9.0+

## Usage

### Logging levels

It is possible to log on different levels. Each logger can support different levels, meaning that it records only log messages on such levels. For example multiple loggers of the same type can be set to support different levels and thus separate logging on such level. Another use case is to further filter messages of specific type declared by its level. 

Levels are inspired by [Apple Logger](https://developer.apple.com/documentation/os/logger).

- `info` for mostly UI related user actions (also called trace)
- `debug` for debugging purposes
- `default`
- `warning` for warnings (also called errors)
- `critical` for critical stuffs such as faults (also called fault)
- `custom(CustomStringConvertible)` available for other level customization if necessary

### Pre-build loggers

#### `NativeLogger`
Wraps the native ```Logger``` to log messages both in the Xcode console and the Console app. It includes a 'retrieve logs' feature thanks to ``LogStore``, this feature is only available from iOS version 15 and later.

#### `FileLogger`

Enables logging to a file. Each log file relates to a single day data. Another day, another log file is used. `numberOfLogFiles` specifies the number of log files that are stored. In other words, how many days back (log files) should be kept. If the last log file is filled, the first one gets overriden using the simplest Round-robin strategy.

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

Here is an example of how to initialize the logger to use `FileLogger`, `NativeLogger` and previously created custom `CrashLyticsLogger`:

```

let fileLogger = FileLogger()
fileLogger.levels = [.warn, .error]

let nativeLogger = NativeLogger(
    bundleIdentifier: Bundle.main.bundleIdentifier ?? "---",
    category: "swift-logger"
)

let crashlyticsLogger = CrashLyticsLogger()

let loggerManager = LoggerManager(loggers: [fileLogger, nativeLogger, crashlyticsLogger])
```

for further info see the sample app

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

Each logger can choose whether it runs asynchronously via `isAsynchronous`. `LoggerManager` invokes synchronous loggers immediately on the caller's thread, which makes console output visible right away when debugging with breakpoints or when the app terminates unexpectedly. Asynchronous loggers are dispatched on a shared serial background queue. `FileLogger` uses asynchronous execution by default, while the built-in non-file loggers stay synchronous by default.

![asyncserial](https://user-images.githubusercontent.com/2511209/33495945-a2732168-d6c8-11e7-9a77-519204be448a.png)

### Sending file logs via mail

The framework provides `SendMailView` that has a pre-configured SwiftUI `View` that, when presented, will offer the option to send all log files via mail.

### Displaying file logs in `FileLogsTable`

The framework provides an example of `SwiftUI` `View` called `FileLogsTable`. It displays all log records stored via `FileLogger` in a table view.  
The `View` is available within `SwiftLoggerSampleApp`.

## License

`Logger` is released under the [MIT License](LICENSE).
