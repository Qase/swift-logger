//
//  ApplicationCallbackLogger.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation
#if canImport(WatchKit)
import WatchKit

public enum ApplicationCallbackType: String, CaseIterable {
    case didBecomeActive
    case willResignActive
    case didEnterBackground
    case didFinishLaunching
    case willEnterForeground

    var notificationName: NSNotification.Name {
        switch self {
        case .didBecomeActive:
            return WKApplication.didBecomeActiveNotification
        case .willResignActive:
            return WKApplication.willResignActiveNotification
        case .didEnterBackground:
            return WKApplication.didEnterBackgroundNotification
        case .didFinishLaunching:
            return WKApplication.didFinishLaunchingNotification
        case .willEnterForeground:
            return WKApplication.willEnterForegroundNotification
        }
    }
}

#elseif canImport(UIKit)
import UIKit

public enum ApplicationCallbackType: String, CaseIterable {
    case willTerminate
    case didBecomeActive
    case willResignActive
    case didEnterBackground
    case didFinishLaunching
    case willEnterForeground
    case significantTimeChange
    case userDidTakeScreenshot
    case didReceiveMemoryWarning
    case protectedDataDidBecomeAvailable
    case backroundRefreshStatusDidChange
    case protectedDataWillBecomeUnavailable

    var notificationName: NSNotification.Name {
        switch self {
        case .willTerminate:
            return UIApplication.willTerminateNotification
        case .didBecomeActive:
            return UIApplication.didBecomeActiveNotification
        case .willResignActive:
            return UIApplication.willResignActiveNotification
        case .didEnterBackground:
            return UIApplication.didEnterBackgroundNotification
        case .didFinishLaunching:
            return UIApplication.didFinishLaunchingNotification
        case .willEnterForeground:
            return UIApplication.willEnterForegroundNotification
        case .significantTimeChange:
            return UIApplication.significantTimeChangeNotification
        case .userDidTakeScreenshot:
            return UIApplication.userDidTakeScreenshotNotification
        case .didReceiveMemoryWarning:
            return UIApplication.didReceiveMemoryWarningNotification
        case .protectedDataDidBecomeAvailable:
            return UIApplication.protectedDataDidBecomeAvailableNotification
        case .backroundRefreshStatusDidChange:
            return UIApplication.backgroundRefreshStatusDidChangeNotification
        case .protectedDataWillBecomeUnavailable:
            return UIApplication.protectedDataWillBecomeUnavailableNotification
        }
    }
}

#elseif canImport(Cocoa)
import Cocoa

public enum ApplicationCallbackType: String, CaseIterable {
    case didBecomeActiveNotification
    case didChangeOcclusionStateNotification
    case didChangeScreenParametersNotification
    case didFinishLaunchingNotification
    case didFinishRestoringWindowsNotification
    case didHideNotification
    case didResignActiveNotification
    case didUnhideNotification
    case willBecomeActiveNotification
    case willFinishLaunchingNotification
    case willHideNotification
    case willResignActiveNotification
    case willTerminateNotification
    case willUnhideNotification

    var notificationName: NSNotification.Name {
        switch self {
        case .didBecomeActiveNotification:
            return NSApplication.didBecomeActiveNotification
        case .didChangeOcclusionStateNotification:
            return NSApplication.didChangeOcclusionStateNotification
        case .didChangeScreenParametersNotification:
            return NSApplication.didChangeScreenParametersNotification
        case .didFinishLaunchingNotification:
            return NSApplication.didFinishLaunchingNotification
        case .didFinishRestoringWindowsNotification:
            return NSApplication.didFinishRestoringWindowsNotification
        case .didHideNotification:
            return NSApplication.didHideNotification
        case .didResignActiveNotification:
            return NSApplication.didResignActiveNotification
        case .didUnhideNotification:
            return NSApplication.didUnhideNotification
        case .willBecomeActiveNotification:
            return NSApplication.willBecomeActiveNotification
        case .willFinishLaunchingNotification:
            return NSApplication.willFinishLaunchingNotification
        case .willHideNotification:
            return NSApplication.willHideNotification
        case .willResignActiveNotification:
            return NSApplication.willResignActiveNotification
        case .willTerminateNotification:
            return NSApplication.willTerminateNotification
        case .willUnhideNotification:
            return NSApplication.willUnhideNotification
        }

    }
}
#endif

public class ApplicationCallbackLogger {
    private let level: Level
    private let logMessage: (Level, String) -> Void

    init(
        callbacks: [ApplicationCallbackType] = ApplicationCallbackType.allCases,
        level: Level = .debug,
        logMessage: @escaping (Level, String) -> Void
    ) {
        self.level = level
        self.logMessage = logMessage
        
        callbacks.forEach { callback in
            #if canImport(UIKit) || canImport(WatchKit)
            let selector = Selector(callback.rawValue)
            #elseif os(macOS)
            let selector = #selector(logNotification(_:))
            #endif
            NotificationCenter.default.addObserver(self, selector: selector, name: callback.notificationName, object: nil)
        }
    }
}

// MARK: - ApplicationCallbackLogger + notification callbacks

extension ApplicationCallbackLogger {
    private func log(_ message: String, onLevel level: Level) {
        logMessage(level, message)
    }

    #if canImport(UIKit) || canImport(WatchKit)
    @objc
    fileprivate func willTerminate() {
        log("\(#function)", onLevel: level)
    }

    @objc
    fileprivate func didBecomeActive() {
        log("\(#function)", onLevel: level)
    }

    @objc
    fileprivate func willResignActive() {
        log("\(#function)", onLevel: level)
    }

    @objc
    fileprivate func didEnterBackground() {
        log("\(#function)", onLevel: level)
    }

    @objc
    fileprivate func didFinishLaunching() {
        log("\(#function)", onLevel: level)
    }

    @objc
    fileprivate func willEnterForeground() {
        log("\(#function)", onLevel: level)
    }

    @objc
    fileprivate func significantTimeChange() {
        log("\(#function)", onLevel: level)
    }

    @objc
    fileprivate func userDidTakeScreenshot() {
        log("\(#function)", onLevel: level)
    }

    @objc
    fileprivate func didChangeStatusBarFrame() {
        log("\(#function)", onLevel: level)
    }

    @objc
    fileprivate func didReceiveMemoryWarning() {
        log("\(#function)", onLevel: level)
    }

    @objc
    fileprivate func willChangeStatusBarFrame() {
        log("\(#function)", onLevel: level)
    }

    @objc
    fileprivate func didChangeStatusBarOrientation() {
        log("\(#function)", onLevel: level)
    }

    @objc
    fileprivate func willChangeStatusBarOrientation() {
        log("\(#function)", onLevel: level)
    }

    @objc
    fileprivate func protectedDataDidBecomeAvailable() {
        log("\(#function)", onLevel: level)
    }

    @objc
    fileprivate func backroundRefreshStatusDidChange() {
        log("\(#function)", onLevel: level)
    }

    @objc
    fileprivate func protectedDataWillBecomeUnavailable() {
        log("\(#function)", onLevel: level)
    }

    #elseif os(macOS)
    @objc
    fileprivate func logNotification(_ notification: NSNotification) {

        let notificationName = notification.name.rawValue
            .replacingOccurrences(of: "NSApplication", with: "NSApplication: ")
            .replacingOccurrences(of: "Notification", with: "")

        log("\(notificationName)", onLevel: level)
    }
    #endif
}
