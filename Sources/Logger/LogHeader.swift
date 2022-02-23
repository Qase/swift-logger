//
//  LogHeader.swift
//  
//
//  Created by Martin Troup on 01.11.2021.
//

import Foundation

public struct LogHeader {
    public let date: Date
    public let level: Level
    public let dateFormatter: DateFormatter

    public init(date: Date, level: Level, dateFormatter: DateFormatter) {
        self.date = date
        self.level = level
        self.dateFormatter = dateFormatter
    }
}

// MARK: - LogHeader + Hashable & Equatable

extension LogHeader: Hashable, Equatable {}
