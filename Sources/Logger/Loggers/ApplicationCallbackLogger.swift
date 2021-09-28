//
//  ApplicationCallbackLogger.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

// TODO: Refactor using SwiftUI instead of UIKit

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

class ApplicationCallbackLogger {
    weak var delegate: ApplicationCallbackLoggerDelegate?

    var callbacks: [ApplicationCallbackType]? = [] {
        didSet {
            let _oldValue = oldValue?.count == 0 ? ApplicationCallbackType.allCases : oldValue
            let _callbacks = callbacks?.count == 0 ? ApplicationCallbackType.allCases : callbacks

            removeNotifications(for: getCallbacksToRemove(from: _oldValue, basedOn: _callbacks))
            addNotifications(for: getCallbacksToAdd(from: _callbacks, basedOn: _oldValue))
        }
    }

    var level: Level = .debug

    init() {
        addNotifications(for: ApplicationCallbackType.allCases)
    }

    /// Method to get array of callbacks to remove (thus those, who are in oldCallbacks but not in newCallbacks).
    /// The method is used for removeNotifications(for:) method.
    ///
    /// - Parameters:
    ///   - oldCallbacks: old array of callbacks
    ///   - newCallbacks: new array of callbacks
    /// - Returns: array of callbacks to be removed
    private func getCallbacksToRemove(from oldCallbacks: [ApplicationCallbackType]?, basedOn newCallbacks: [ApplicationCallbackType]?) -> [ApplicationCallbackType] {
        oldCallbacks?.filter { !(newCallbacks?.contains($0) ?? false) } ?? []
    }

    /// Method to get array of callbacks to add (thus those, who are in newCallbacks but not in oldCallbacks).
    /// The method is used for addNotifications(for:) method.
    ///
    /// - Parameters:
    ///   - newCallbacks: new array of callbacks
    ///   - oldCallbacks: old array of callbacks
    /// - Returns: array of callbacks to be added
    private func getCallbacksToAdd(from newCallbacks: [ApplicationCallbackType]?, basedOn oldCallbacks: [ApplicationCallbackType]?) -> [ApplicationCallbackType] {
        newCallbacks?.filter { !(oldCallbacks?.contains($0) ?? false) } ?? []
    }

    /// Method to remove specific Application's notification callbacks
    ///
    /// - Parameter callbacks: callbacks to be removed
    private func removeNotifications(`for` callbacks: [ApplicationCallbackType]) {
        callbacks.forEach { (callback) in
            NotificationCenter.default.removeObserver(self, name: callback.notificationName, object: nil)
        }
    }

    /// Method to add specific Application's notification callbacks
    ///
    /// - Parameter callbacks: callbacks to be added
    private func addNotifications(`for` callbacks: [ApplicationCallbackType]) {

        callbacks.forEach { (callback) in
            #if canImport(UIKit)
            let selector = Selector(callback.rawValue)
            #elseif os(OSX)
            let selector = #selector(logNotification(_:))
            #endif
            NotificationCenter.default.addObserver(self, selector: selector, name: callback.notificationName, object: nil)
        }
    }
}

// MARK: - Application's notification callbacks
extension ApplicationCallbackLogger {
    private func log(_ message: String, onLevel level: Level) {
        delegate?.logApplicationCallback(message, onLevel: level)
    }

    #if canImport(UIKit)
    @objc fileprivate func willTerminate() {
        log("\(#function)", onLevel: level)
    }

    @objc fileprivate func didBecomeActive() {
        log("\(#function)", onLevel: level)
    }

    @objc fileprivate func willResignActive() {
        log("\(#function)", onLevel: level)
    }

    @objc fileprivate func didEnterBackground() {
        log("\(#function)", onLevel: level)
    }

    @objc fileprivate func didFinishLaunching() {
        log("\(#function)", onLevel: level)
    }

    @objc fileprivate func willEnterForeground() {
        log("\(#function)", onLevel: level)
    }

    @objc fileprivate func significantTimeChange() {
        log("\(#function)", onLevel: level)
    }

    @objc fileprivate func userDidTakeScreenshot() {
        log("\(#function)", onLevel: level)
    }

    @objc fileprivate func didChangeStatusBarFrame() {
        log("\(#function)", onLevel: level)
    }

    @objc fileprivate func didReceiveMemoryWarning() {
        log("\(#function)", onLevel: level)
    }

    @objc fileprivate func willChangeStatusBarFrame() {
        log("\(#function)", onLevel: level)
    }

    @objc fileprivate func didChangeStatusBarOrientation() {
        log("\(#function)", onLevel: level)
    }

    @objc fileprivate func willChangeStatusBarOrientation() {
        log("\(#function)", onLevel: level)
    }

    @objc fileprivate func protectedDataDidBecomeAvailable() {
        log("\(#function)", onLevel: level)
    }

    @objc fileprivate func backroundRefreshStatusDidChange() {
        log("\(#function)", onLevel: level)
    }

    @objc fileprivate func protectedDataWillBecomeUnavailable() {
        log("\(#function)", onLevel: level)
    }

    #elseif os(OSX)
    @objc fileprivate func logNotification(_ notification: NSNotification) {

        let notificationName = notification.name.rawValue
            .replacingOccurrences(of: "NSApplication", with: "NSApplication: ")
            .replacingOccurrences(of: "Notification", with: "")

        log("\(notificationName)", onLevel: level)
    }
    #endif
}
