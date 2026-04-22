//
//  LogHeader.swift
//  
//
//  Created by Martin Troup on 01.11.2021.
//

import Foundation

public struct LogHeader: Sendable {
    public let date: Date
    public let level: Level

    public init(date: Date, level: Level) {
        self.date = date
        self.level = level
    }
}

// MARK: - LogHeader + Hashable & Equatable

extension LogHeader: Hashable, Equatable {}
