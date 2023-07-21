//
//  LogEntryEncoding.swift
//  
//
//  Created by Radek Čep on 23.02.2022.
//

import Foundation

public protocol LogEntryEncoding {
    /// A function to encode an instance of `LogEntry` into a `String`.
    ///
    /// - Parameter logEntry: An instance of `LogEntry` to be encoded
    /// - Returns: Encoded `LogEntry` instance
    func encode(_ logEntry: LogEntry, verbose: Bool) -> String
}
