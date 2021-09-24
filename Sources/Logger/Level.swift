//
//  Level.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation

/// Enum representing different possible levels for log messages.
public enum Level: String {
    case error = "ERROR"
    case warn = "WARNING"
    case info = "INFO"
    case debug = "DEBUG"
    case verbose = "VERBOSE"
    case system = "SYSTEM"
    case process = "PROCESS"
}
