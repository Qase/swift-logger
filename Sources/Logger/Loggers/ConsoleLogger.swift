//
//  ConsoleLogger.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation

/// Pre-built logger that logs to the console.
public class ConsoleLogger: Logging {
    public var levels: [Level] = [.info]

    public init() {}

    public func log(_ message: String, onLevel level: Level) {
        print("\(messageHeader(forLevel: level)) \(message)")
    }
}
