//
//  FileLogEntry.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation

public struct FileLogEntry {
    public let header: LogHeader
    public let body: String

    public init(header: LogHeader, body: String) {
        self.header = header
        self.body = body
    }
}

// MARK: - FileLog + Hashable & Equatable

extension FileLogEntry: Hashable, Equatable {}

// MARK: - FileLog + parsing

extension FileLogEntry {
    init?(rawValue string: String, dateFormatter: DateFormatter) {
        let elements = string.split(separator: "]", maxSplits: 2, omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard elements.count == 2 else { return nil }

        guard let header = LogHeader(rawValue: elements[0], dateFormatter: dateFormatter) else { return nil }

        self.header = header
        self.body = elements[1]
    }
}

// MARK: - FileLog + CustomStringConvertible

extension FileLogEntry: CustomStringConvertible {
    public var description: String {
        "\(header) \(body)"
    }
}

