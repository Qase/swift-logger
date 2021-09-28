//
//  AppDelegate.swift
//  SwiftLoggerSampleApp
//
//  Created by Dagy Tran on 28.09.2021.
//

import Logger
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Loggers setup
        let logManager = LogManager.shared

        logManager.setApplicationCallbackLogger(onLevel: .info)

        let consoleLogger = ConsoleLogger()
        consoleLogger.levels = [.warn, .debug]
        logManager.add(consoleLogger)

        let fileLogger = FileLogger()
        fileLogger.levels = [.error, .warn]
        logManager.add(fileLogger)

        return true
    }
}
