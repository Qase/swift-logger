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

    private let logRecordSeparator: String
    private let logHeaderOpeningSeparator: String
    private let logHeaderClosingSeparator: String
    private let logLocationSeparator: String
    private let lineIdentifier: String
    private let messageSeparator: String
    private let dateFormatter: DateFormatter

    public init(
        logRecordSeparator: String = "|>",
        logHeaderOpeningSeparator: String = "[~",
        logHeaderClosingSeparator: String = "~]",
        logLocationSeparator: String = "—",
        lineIdentifier: String = "line",
        messageSeparator: String = ":",
        dateFormatter: DateFormatter = DateFormatter.dateTimeFormatter
    ) {
        self.logRecordSeparator = logRecordSeparator
        self.logHeaderOpeningSeparator = logHeaderOpeningSeparator
        self.logHeaderClosingSeparator = logHeaderClosingSeparator
        self.logLocationSeparator = logLocationSeparator
        self.lineIdentifier = lineIdentifier
        self.messageSeparator = messageSeparator
        self.dateFormatter = dateFormatter
    }

    public func decode(_ rawEntries: String) throws -> [LogEntry] {
        let pattern =
            "\(logRecordSeparator.escapingRegexCharacters)\\s*" +
            "\(logHeaderOpeningSeparator.escapingRegexCharacters)(?<\(Elements.level.rawValue)>\\S*)\\s\\s*" +
            "(?<\(Elements.date.rawValue)>.*)\(logHeaderClosingSeparator.escapingRegexCharacters)\\s\\s*" +
            "(?<\(Elements.fileName.rawValue)>.*)\\s\\s*" +
            "\(logLocationSeparator)\\s\\s*(?<\(Elements.functionName.rawValue)>.*)\\s\\s*" +
            "\(logLocationSeparator)\\s\\s*\(lineIdentifier)\\s\\s*(?<\(Elements.lineNumber.rawValue)>\\d*)" +
            "\(messageSeparator)\\s\\s*(?<\(Elements.message.rawValue)>(.*\\s*(?!\(logRecordSeparator.escapingRegexCharacters)))*)"

        let range = NSRange(location: 0, length: rawEntries.utf16.count)

        return try NSRegularExpression(pattern: pattern, options: [])
            .matches(in: rawEntries, options: [], range: range)
            .compactMap { match in
                let levelRange = match.range(withName: Elements.level.rawValue)
                let dateRange = match.range(withName: Elements.date.rawValue)
                let fileNameRange = match.range(withName: Elements.fileName.rawValue)
                let functionNameRange = match.range(withName: Elements.functionName.rawValue)
                let lineNumberRange = match.range(withName: Elements.lineNumber.rawValue)
                let messageRange = match.range(withName: Elements.message.rawValue)

                guard
                    let levelRawValue = rawEntries.at(levelRange),
                    let dateString = rawEntries.at(dateRange),
                    let date = dateFormatter.date(from: dateString),
                    let fileName = rawEntries.at(fileNameRange),
                    let functionName = rawEntries.at(functionNameRange),
                    let lineNumberString = rawEntries.at(lineNumberRange),
                    let line = Int(lineNumberString),
                    let message = rawEntries.at(messageRange)?.trimmingCharacters(in: .whitespacesAndNewlines)
                else {
                    return nil
                }

                return LogEntry(
                    header: .init(
                        date: date,
                        level: Level(rawValue: levelRawValue),
                        dateFormatter: dateFormatter
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
