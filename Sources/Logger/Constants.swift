//
//  Constants.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation

public struct Constants {
    struct UserDefaultsKeys {
        static let logDirUrl = "logDirUrl"
        static let currentLogFileNumber = "currentLogFileNumber"
        static let dateOfLastLog = "dateOfLastLog"
        static let numberOfLogFiles = "numOfLogFiles"
    }

    public struct Separators {
        /// The between used file records
        public static let logFileRecordSeparator = "|>"
        /// The opening separator encapsulating the LogHeader
        public static let logHeaderOpeningSeparator = "[~"
        /// The closing separator encapsulating the LogHeader
        public static let logHeaderClosingSeparator = "~]"
        /// The separator of LogLocation components
        public static let logLocationSeparator = "—"
        /// The separator before the line number
        public static let lineSeparator = "line"
        /// The separator between the header + location section and the logged message
        public static let messageSeparator = ":"
    }

    public struct Queues {
        public static let serial = "com.swift.loggerSerial"
        public static let concurrent = "com.swift.loggerConcurrent"
    }
}
