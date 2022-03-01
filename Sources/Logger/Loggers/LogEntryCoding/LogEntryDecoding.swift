//
//  LogEntryDecoding.swift
//  
//
//  Created by Radek Čep on 23.02.2022.
//

import Foundation

public protocol LogEntryDecoding {
    /// A function to decode a raw `FileLogEntry` array. E.g. from a log file. To an instance of `[FileLogEntry]`
    ///
    /// - Parameter rawEntry: A `String` representation of `[FileLogEntry]`
    /// - Returns: Decoded `[FileLogEntry]` instance
    func decode(_ rawEntries: String) throws -> [FileLogEntry]
}
