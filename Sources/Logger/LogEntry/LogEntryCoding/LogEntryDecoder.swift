//
//  LogEntryDecoder.swift
//  
//
//  Created by Radek Čep on 23.02.2022.
//

import Foundation

public struct LogEntryDecoder: LogEntryDecoding {
    private enum Elements: String {
        case level, date, fileName, functionName, lineNumber, message
    }

    private let logEntryConfig: LogEntryConfig

    public init(
        logEntryConfig: LogEntryConfig = .init()
    ) {
        self.logEntryConfig = logEntryConfig
    }

    public func decode(_ rawEntry: String) throws -> LogEntry? {
        let pattern =
            "\(logEntryConfig.logRecordSeparator.escapingRegexCharacters)\\s*" +
            "\(logEntryConfig.logHeaderOpeningSeparator.escapingRegexCharacters)(?<\(Elements.level.rawValue)>\\S*)\\s\\s*" +
            "(?<\(Elements.date.rawValue)>.*)\(logEntryConfig.logHeaderClosingSeparator.escapingRegexCharacters)\\s\\s*" +
            "(?<\(Elements.fileName.rawValue)>.*)\\s\\s*" +
            "\(logEntryConfig.logLocationSeparator)\\s\\s*(?<\(Elements.functionName.rawValue)>.*)\\s\\s*" +
            "\(logEntryConfig.logLocationSeparator)\\s\\s*\(logEntryConfig.lineIdentifier)\\s\\s*(?<\(Elements.lineNumber.rawValue)>\\d*)" +
            "\(logEntryConfig.messageSeparator)\\s\\s*" +
            "(?<\(Elements.message.rawValue)>(.*\\s*(?!\(logEntryConfig.logRecordSeparator.escapingRegexCharacters)))*)"

        let range = NSRange(location: 0, length: rawEntry.utf16.count)

        return try NSRegularExpression(pattern: pattern, options: [])
            .firstMatch(in: rawEntry, options: [], range: range)
            .flatMap { match in
                let levelRange = match.range(withName: Elements.level.rawValue)
                let dateRange = match.range(withName: Elements.date.rawValue)
                let fileNameRange = match.range(withName: Elements.fileName.rawValue)
                let functionNameRange = match.range(withName: Elements.functionName.rawValue)
                let lineNumberRange = match.range(withName: Elements.lineNumber.rawValue)
                let messageRange = match.range(withName: Elements.message.rawValue)

                guard
                    let levelRawValue = rawEntry.at(levelRange),
                    let dateString = rawEntry.at(dateRange),
                    let date = logEntryConfig.dateFormatter.date(from: dateString),
                    let fileName = rawEntry.at(fileNameRange),
                    let functionName = rawEntry.at(functionNameRange),
                    let lineNumberString = rawEntry.at(lineNumberRange),
                    let line = Int(lineNumberString),
                    let message = rawEntry.at(messageRange)?.trimmingCharacters(in: .whitespacesAndNewlines)
                else {
                    return nil
                }

                return LogEntry(
                    header: .init(
                        date: date,
                        level: Level(rawValue: levelRawValue),
                        dateFormatter: logEntryConfig.dateFormatter
                    ),
                    location: .init(
                        fileName: fileName,
                        function: functionName,
                        line: line
                    ),
                    message: message
                )
            }
    }
}

private extension String {
    var regexCharacters: [Self] {
        [".", "+", "*", "?", "^", "$", "(", ")", "[", "]", "{", "}", "|", "\\"]
    }

    /// Adds a backslash to characters when needed. E.g.: "() abc" returns "\(\) abc"
    var escapingRegexCharacters: Self {
        self
            .map(String.init)
            .map { character in
                regexCharacters.contains(character) ? "\\\(character)" : character
            }
            .joined()
    }

    /// Creates a `String` at the given range
    ///
    /// - Parameter range: A range of the substring
    /// - Returns: A `String` at the given range
    func at(_ nsRange: NSRange) -> Self? {
        Range(nsRange, in: self)
            .map { self[$0] }
            .map(String.init)
    }
}
