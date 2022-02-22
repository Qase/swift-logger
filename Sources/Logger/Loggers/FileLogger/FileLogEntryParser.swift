import Foundation

struct FileLogEntryParser {
    private enum Elements: String {
        case level, date, fileName, functionName, lineNumber, message
    }

    private let logFileRecordSeparator: String
    private let logHeaderOpeningSeparator: String
    private let logHeaderClosingSeparator: String
    private let logLocationSeparator: String
    private let lineIdentifier: String
    private let messageSeparator: String

    init(
        logFileRecordSeparator: String,
        logHeaderOpeningSeparator: String,
        logHeaderClosingSeparator: String,
        logLocationSeparator: String,
        lineIdentifier: String,
        messageSeparator: String
    ) {
        self.logFileRecordSeparator = logFileRecordSeparator
        self.logHeaderOpeningSeparator = logHeaderOpeningSeparator
        self.logHeaderClosingSeparator = logHeaderClosingSeparator
        self.logLocationSeparator = logLocationSeparator
        self.lineIdentifier = lineIdentifier
        self.messageSeparator = messageSeparator
    }

    func parse(_ record: String, dateFormatter: DateFormatter) throws -> FileLogEntry? {
        let pattern =
            "^(\(logFileRecordSeparator.escapingRegexCharacters))*\\s*" +
            "\(logHeaderOpeningSeparator.escapingRegexCharacters)(?<\(Elements.level.rawValue)>\\S*)\\s\\s*" +
            "(?<\(Elements.date.rawValue)>.*)\(logHeaderClosingSeparator.escapingRegexCharacters)\\s\\s*" +
            "(?<\(Elements.fileName.rawValue)>.*)\\s\\s*" +
            "\(logLocationSeparator)\\s\\s*(?<\(Elements.functionName.rawValue)>.*)\\s\\s*" +
            "\(logLocationSeparator)\\s\\s*\(lineIdentifier)\\s\\s*(?<\(Elements.lineNumber.rawValue)>\\d*)" +
            "\(messageSeparator)\\s\\s*(?<\(Elements.message.rawValue)>(.*\\s*)*)"

        let range = NSRange(location: 0, length: record.utf16.count)
        let regularExpression = try NSRegularExpression(pattern: pattern, options: [])
        let match = regularExpression.firstMatch(in: record, options: [], range: range)

        guard
            let levelRange = match?.range(withName: Elements.level.rawValue),
            let levelRawValue = record[levelRange],

            let dateRange = match?.range(withName: Elements.date.rawValue),
            let dateString = record[dateRange],
            let date = dateFormatter.date(from: dateString),

            let fileNameRange = match?.range(withName: Elements.fileName.rawValue),
            let fileName = record[fileNameRange],

            let functionNameRange = match?.range(withName: Elements.functionName.rawValue),
            let functionName = record[functionNameRange],

            let lineNumberRange = match?.range(withName: Elements.lineNumber.rawValue),
            let lineNumberString = record[lineNumberRange],
            let line = Int(lineNumberString),

            let messageRange = match?.range(withName: Elements.message.rawValue),
            let message = record[messageRange]?.trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            return nil
        }

        return FileLogEntry(
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
            body: message
        )
    }
}

private extension String {
    subscript(index: NSRange) -> Self? {
        get {
            Range(index, in: self)
                .map { self[$0] }
                .map(String.init)
        }
    }

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
}
