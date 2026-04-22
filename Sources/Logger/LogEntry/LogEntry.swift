//
//  LogEntry.swift
//  
//
//  Created by Martin Troup on 23.11.2021.
//

import Foundation

public struct LogEntry: Sendable {
    public let header: LogHeader
    public let location: LogLocation
    public let message: String

    public init(header: LogHeader, location: LogLocation, message: CustomStringConvertible) {
        self.header = header
        self.location = location
        self.message = message.description
    }
}
