//
//  FileLog.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation

public struct FileLog {
    public let header: LogHeader
    public let body: String
}

// MARK: - FileLog + Hashable & Equatable

extension FileLog: Hashable, Equatable {}

// MARK: - FileLog + parsing

extension FileLog {
    init?(rawValue string: String, dateFormatter: DateFormatter) {
        let elements = string.split(separator: "]")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard elements.count == 2 else { return nil }

        guard let header = LogHeader(rawValue: elements[0], dateFormatter: dateFormatter) else { return nil }

        self.header = header
        self.body = elements[1]
    }
}


