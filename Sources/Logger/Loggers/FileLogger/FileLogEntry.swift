//
//  FileLogEntry.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation

public struct FileLogEntry {
    public let header: LogHeader
    public let location: LogLocation
    public let body: String

    public init(header: LogHeader, location: LogLocation, body: String) {
        self.header = header
        self.location = location
        self.body = body
    }
}

// MARK: - FileLog + Hashable & Equatable

extension FileLogEntry: Hashable, Equatable {}
