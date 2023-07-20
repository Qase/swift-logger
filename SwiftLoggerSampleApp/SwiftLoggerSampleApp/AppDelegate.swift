//
//  AppDelegate.swift
//  SwiftLoggerSampleApp
//
//  Created by Dagy Tran on 28.09.2021.
//

import Logger
import UIKit

var fileLogger: FileLogger!
var appLogger: LoggerManager!

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Loggers setup
        let nativeLogger = NativeLogger(
            bundleIdentifier: "cz.qase.swift-logger",
            category: "SwiftLoggerSampleApp"
        )

        fileLogger = try? FileLogger()
        fileLogger?.levels = [.error, .warn, .info]

        let loggers: [Logging?] = [nativeLogger, fileLogger]

        appLogger = LoggerManager(
            loggers: loggers.compactMap { $0 },
            applicationCallbackLoggerBundle: (callbacks: ApplicationCallbackType.allCases, level: .info)
        )

        return true
    }
}
