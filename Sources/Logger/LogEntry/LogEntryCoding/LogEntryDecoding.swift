//
//  LogEntryDecoding.swift
//  
//
//  Created by Radek Čep on 23.02.2022.
//

import Foundation

public protocol LogEntryDecoding {
    /// A function to decode a raw `LogEntry`. E.g. from a log file. To an instance of `LogEntry`
    ///
    /// - Parameter rawEntry: A `String` representation of `LogEntry`
    /// - Returns: Decoded `LogEntry` instance
    func decode(_ rawEntry: String) throws -> LogEntry?
}
