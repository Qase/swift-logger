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
    public func configure() {}

    public func messageHeader(forLevel level: Level) -> String {
        "[\(level.rawValue) \(Date().toShortenedDateString())]"
    }

    func doesLog(forLevel level: Level) -> Bool {
        levels.contains(level)
    }
}
