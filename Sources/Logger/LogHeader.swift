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

    public var rawValue: String {
        "[\(level.rawValue) \(dateFormatter.string(from: date))]"
    }
}

// MARK: - LogHeader + Hashable & Equatable

extension LogHeader: Hashable, Equatable {}

// MARK: - FileLogHeader + parsing init

extension LogHeader {
    init?(rawValue: String, dateFormatter: DateFormatter) {
        let parse: (String, DateFormatter) -> (Level, Date)? = { string, dateFormatter in
            let trimmedString = string
                .replacingOccurrences(of: "(\\[|\\])", with: "", options: .regularExpression)

            guard let firstSpace = trimmedString.firstIndex(of: " ") else { return nil }

            let levelString = trimmedString.prefix(upTo: firstSpace)
            let dateString = trimmedString.suffix(from: firstSpace)

            guard
                let level = Level(rawValue: String(levelString)),
                let date = dateFormatter.date(from: String(dateString))
            else {
                return nil
            }

            return (level, date)
        }

        guard let (level, date) = parse(rawValue, dateFormatter) else {
            return nil
        }

        self.level = level
        self.date = date
        self.dateFormatter = dateFormatter
    }
}

// MARK: - String + firstMatch

private extension String {
    func firstMatch(forRegexPattern regexString: String) -> String? {
        do {
            let pattern = try NSRegularExpression(pattern: regexString)

            return pattern.firstMatch(in: self, range: NSRange(startIndex..., in: self))
                .flatMap { Range($0.range, in: self) }
                .flatMap { self[$0] }
                .map(String.init)
        } catch {
            return nil
        }
    }
}
