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
    func log(_ message: String, onLevel level: Level)
}

extension Logging {
    static public var dateFormatter: DateFormatter {
        DateFormatter.monthsDaysTimeFormatter
    }

    public func configure() {}

    public func messageHeader(forLevel level: Level) -> String {
        LogHeader(date: Date(), level: level, dateFormatter: Self.dateFormatter).rawValue
    }

    func doesLog(forLevel level: Level) -> Bool {
        levels.contains(level)
    }
}


extension Array where Element == Logging {
    func availableLoggers(forLevel level: Level) -> Self {
        self.filter { $0.doesLog(forLevel: level) }
    }
}
