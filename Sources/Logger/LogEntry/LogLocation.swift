//
//  LogLocation.swift
//  
//
//  Created by Martin Troup on 23.11.2021.
//

import Foundation

public struct LogLocation {
    public let fileName: String
    public let function: String
    public let line: Int

    public init(fileName: String, function: String, line: Int) {
        self.fileName = fileName
        self.function = function
        self.line = line
    }
}

// MARK: - LogHeader + Hashable & Equatable

extension LogLocation: Hashable, Equatable {}
