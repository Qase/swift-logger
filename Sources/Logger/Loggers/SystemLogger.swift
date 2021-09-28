//
//  SystemLogger.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation
import os

/// Pre-built logger that wraps system os_logger
public class SystemLogger: Logging {

    private var logger: OSLog

    public init(subsystem: String, category: String) {
        logger = OSLog(subsystem: subsystem, category: category)
    }

    public var levels: [Level] = [.info]

    public func log(_ message: String, onLevel level: Level) {
        let staticMessage = "\(messageHeader(forLevel: level)) \(message)"
        os_log("%@", log: logger, type: level.logType, staticMessage)
    }
}

private extension Level {
    var logType: OSLogType {
        switch self {
        case .info:
            return .info
        case .debug:
            return .debug
        case .verbose, .warn, .error:
            return .default
        case .system:
            return .fault
        case .process:
            return .error
        }
    }
}
