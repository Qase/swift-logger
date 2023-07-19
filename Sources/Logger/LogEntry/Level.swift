//
//  Level.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation
import OSLog

/// Enum representing different possible levels for log messages. Basically mapped object from the native OSLogEntryLog.Level
public enum Level: CaseIterable {
    case debug // trace
    case info
    case `default`
    case error // warning
    case fault // critical
    case custom(CustomStringConvertible)

    public static var allCases: [Level] {
        [
            .debug,
            .info,
            .default,
            .error,
            .fault
        ]
    }

    public var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .default, .custom:
            return .default
        case .error:
            return .error
        case .fault:
            return .fault
        }
    }

    public var description: String {
        switch self {
        case .debug:
            return "🟤"
        case .info:
            return "⚪️"
        case .default:
            return "  "
        case .error:
            return "🟡"
        case .fault:
            return "🔴"
        case let .custom(level):
            return "🟣(\(level))"
        }
    }

    public var rawValue: String {
        switch self {
        case .debug:
            return "debug"
        case .info:
            return "info"
        case .default:
            return "default"
        case .error:
            return "error"
        case .fault:
            return "fault"
        case let .custom(level):
            return level.description
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case Level.debug.rawValue:
            self = .debug
        case Level.info.rawValue:
            self = .info
        case Level.`default`.rawValue:
            self = .`default`
        case Level.error.rawValue:
            self = .error
        case Level.fault.rawValue:
            self = .fault
        default:
            self = .custom(rawValue)
        }
    }
}

// MARK: - Level + Hashable

extension Level: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static func == (lhs: Level, rhs: Level) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}
