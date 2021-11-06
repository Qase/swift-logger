//
//  ApplicationCallbackLogger.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Combine
import Foundation
#if canImport(UIKit)
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

protocol ApplicationCallbackLoggerDelegate: AnyObject {
    func logApplicationCallback(_ message: String, onLevel level: Level)
}

public class ApplicationCallbackLogger {
    private let messageSubject = PassthroughSubject<(level: Level, message: String), Never>()
    var messagePublisher: AnyPublisher<(level: Level, message: String), Never> { messageSubject.eraseToAnyPublisher() }

    private let level: Level

    init(callbacks: [ApplicationCallbackType] = ApplicationCallbackType.allCases, level: Level = .debug) {
        self.level = level
        
        callbacks.forEach { callback in
            #if canImport(UIKit)
            let selector = Selector(callback.rawValue)
            #elseif os(OSX)
            let selector = #selector(logNotification(_:))
            #endif
            NotificationCenter.default.addObserver(self, selector: selector, name: callback.notificationName, object: nil)
        }
    }
}

// MARK: - ApplicationCallbackLogger + notification callbacks

extension ApplicationCallbackLogger {
    private func log(_ message: String, onLevel level: Level) {
        messageSubject.send((level: level, message: message))
    }

    #if canImport(UIKit)
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

    #elseif os(OSX)
    @objc
    fileprivate func logNotification(_ notification: NSNotification) {

        let notificationName = notification.name.rawValue
            .replacingOccurrences(of: "NSApplication", with: "NSApplication: ")
            .replacingOccurrences(of: "Notification", with: "")

        log("\(notificationName)", onLevel: level)
    }
    #endif
}
