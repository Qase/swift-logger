//
//  Logging.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation

public protocol Logging {
    var levels: [Level] { get set }

    func configure()
    func log(_: LogEntry)
}

extension Logging {
    public func configure() {}

    func doesLog(forLevel level: Level) -> Bool {
        levels.contains(level)
    }
}


extension Array where Element == Logging {
    func availableLoggers(forLevel level: Level) -> Self {
        filter { $0.doesLog(forLevel: level) }
    }
}
