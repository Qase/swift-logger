//
//  ConsoleLogger.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation

/// Pre-built logger that logs to the console.
public class ConsoleLogger: Logging {
    public let id: UUID
    public var levels: [Level] = [.info]

    public init(id: UUID = UUID()) {
      self.id = id
    }

    public func log(_ logEntry: LogEntry) {
        print("\(logEntry)")
    }
}
