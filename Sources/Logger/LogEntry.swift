//
//  LogEntry.swift
//  
//
//  Created by Martin Troup on 23.11.2021.
//

import Foundation

public struct LogEntry {
    public let header: LogHeader
    public let location: LogLocation
    public let message: CustomStringConvertible
    public let error: Error?

    public init(
        header: LogHeader,
        location: LogLocation,
        message: CustomStringConvertible,
        error: Error? = nil
    ) {
        self.header = header
        self.location = location
        self.message = message
        self.error = error
    }
}

// MARK: - LogEntry + CustomStringConvertible

extension LogEntry: CustomStringConvertible {
    public var description: String {
        "\(header) \(location): \(message)"
    }
}
