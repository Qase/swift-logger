//
//  Level.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation

/// Enum representing different possible levels for log messages.
public enum Level {
    case error
    case warn
    case info
    case debug
    case verbose
    case system
    case process
    case custom(CustomStringConvertible)

    public static var standardCases: [Level] {
      [
        .error,
        .warn,
        .info,
        .debug,
        .verbose,
        .system,
        .process
      ]
    }

    public var rawValue: String {
        switch self {
        case .error:
            return "ERROR"
        case .warn:
            return "WARNING"
        case .info:
            return "INFO"
        case .debug:
            return "DEBUG"
        case .verbose:
            return "VERBOSE"
        case .system:
            return "SYSTEM"
        case .process:
            return "PROCESS"
        case let .custom(level):
            return level.description
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case Level.error.rawValue:
            self = .error
        case Level.warn.rawValue:
            self = .warn
        case Level.info.rawValue:
            self = .info
        case Level.debug.rawValue:
            self = .debug
        case Level.verbose.rawValue:
            self = .verbose
        case Level.system.rawValue:
            self = .system
        case Level.process.rawValue:
            self = .process
        default:
            // NOTE: Every unknown level is converted to Level.custom
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
