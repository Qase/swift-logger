//
//  LogEntryDecoderTests.swift
//  
//
//  Created by Radek Čep on 22.02.2022.
//

import XCTest
@testable import Logger

class LogEntryDecoderTests: XCTestCase {
    func test_sut_should_parse_line() throws {
        let dateFormatter = DateFormatter.monthsDaysTimeFormatter
        let expectedDate = dateFormatter.date(from: "02-21 15:16:17.189")
        let record = "|> [INFO 02-21 15:16:17.189] FileName.swift - Function - line 42: Some log with special characters ::[]{}()//"

        let sut = LogEntryDecoder(
            logRecordSeparator: "|>",
            logHeaderOpeningSeparator: "[",
            logHeaderClosingSeparator: "]",
            logLocationSeparator: "-",
            lineIdentifier: "line",
            messageSeparator: ":",
            dateFormatter: dateFormatter
        )

        let result = try sut.decode(record)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.header.level.rawValue, "INFO")
        XCTAssertEqual(result.first?.header.date, expectedDate)
        XCTAssertEqual(result.first?.location.fileName, "FileName.swift")
        XCTAssertEqual(result.first?.location.function, "Function")
        XCTAssertEqual(result.first?.location.line, 42)
        XCTAssertEqual(result.first?.body, "Some log with special characters ::[]{}()//")
    }

    func test_sut_should_parse_first_line_only() throws {
        let dateFormatter = DateFormatter.monthsDaysTimeFormatter
        let expectedDate = dateFormatter.date(from: "02-21 15:16:17.189")
        let record = """
            |> [INFO 02-21 15:16:17.189] FileName.swift - Function - line 42: First log with special characters ::[]{}()//
            |> [INFO 02-21 16:17:18.000] FileName2.swift - Function2 - line 43: Second log with special characters ::[]{}()//
            """

        let sut = LogEntryDecoder(
            logRecordSeparator: "|>",
            logHeaderOpeningSeparator: "[",
            logHeaderClosingSeparator: "]",
            logLocationSeparator: "-",
            lineIdentifier: "line",
            messageSeparator: ":",
            dateFormatter: dateFormatter
        )

        let result = try sut.decode(record)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.header.level.rawValue, "INFO")
        XCTAssertEqual(result.first?.header.date, expectedDate)
        XCTAssertEqual(result.first?.location.fileName, "FileName.swift")
        XCTAssertEqual(result.first?.location.function, "Function")
        XCTAssertEqual(result.first?.location.line, 42)
        XCTAssertEqual(result.first?.body, "First log with special characters ::[]{}()//")
    }

    func test_sut_should_parse_encoded_json() throws {
        let dateFormatter = DateFormatter.monthsDaysTimeFormatter
        let expectedDate = dateFormatter.date(from: "02-21 15:16:17.189")
        let record = "|> [INFO 02-21 15:16:17.189] FileName.swift - Function - line 42: {\"array\":[1,2,3],\"text\":\"Text\"}"

        let sut = LogEntryDecoder(
            logRecordSeparator: "|>",
            logHeaderOpeningSeparator: "[",
            logHeaderClosingSeparator: "]",
            logLocationSeparator: "-",
            lineIdentifier: "line",
            messageSeparator: ":",
            dateFormatter: dateFormatter
        )

        let result = try sut.decode(record)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.header.level.rawValue, "INFO")
        XCTAssertEqual(result.first?.header.date, expectedDate)
        XCTAssertEqual(result.first?.location.fileName, "FileName.swift")
        XCTAssertEqual(result.first?.location.function, "Function")
        XCTAssertEqual(result.first?.location.line, 42)
        XCTAssertEqual(result.first?.body, "{\"array\":[1,2,3],\"text\":\"Text\"}")
    }

    func test_sut_should_parse_line_with_an_emoji() throws {
        let dateFormatter = DateFormatter.monthsDaysTimeFormatter
        let expectedDate = dateFormatter.date(from: "02-21 15:16:17.189")
        let record = "|> [INFO 02-21 15:16:17.189] FileName.swift - Function - line 42: [🚗] Some message"

        let sut = LogEntryDecoder(
            logRecordSeparator: "|>",
            logHeaderOpeningSeparator: "[",
            logHeaderClosingSeparator: "]",
            logLocationSeparator: "-",
            lineIdentifier: "line",
            messageSeparator: ":",
            dateFormatter: dateFormatter
        )

        let result = try sut.decode(record)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.header.level.rawValue, "INFO")
        XCTAssertEqual(result.first?.header.date, expectedDate)
        XCTAssertEqual(result.first?.location.fileName, "FileName.swift")
        XCTAssertEqual(result.first?.location.function, "Function")
        XCTAssertEqual(result.first?.location.line, 42)
        XCTAssertEqual(result.first?.body, "[🚗] Some message")
    }

    func test_sut_should_parse_multiline_log() throws {
        let dateFormatter = DateFormatter.monthsDaysTimeFormatter
        let expectedDate = dateFormatter.date(from: "02-21 15:16:17.189")
        let record = """
            |> [INFO 02-21 15:16:17.189] FileName.swift - Function - line 42: Multiline Message:
                line 1
                line 2
                line 3
            """

        let sut = LogEntryDecoder(
            logRecordSeparator: "|>",
            logHeaderOpeningSeparator: "[",
            logHeaderClosingSeparator: "]",
            logLocationSeparator: "-",
            lineIdentifier: "line",
            messageSeparator: ":",
            dateFormatter: dateFormatter
        )

        let result = try sut.decode(record)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.header.level.rawValue, "INFO")
        XCTAssertEqual(result.first?.header.date, expectedDate)
        XCTAssertEqual(result.first?.location.fileName, "FileName.swift")
        XCTAssertEqual(result.first?.location.function, "Function")
        XCTAssertEqual(result.first?.location.line, 42)
        XCTAssertEqual(result.first?.body, """
            Multiline Message:
                line 1
                line 2
                line 3
            """
        )
    }

    func test_sut_should_parse_several_logs() throws {
        let record = """
            |> [INFO 02-21 15:16:17.189] FileName.swift - Function - line 42: Multiline Message:
                line 1
                line 2
                line 3
            |> [INFO 02-21 15:16:17.189] FileName.swift - Function - line 42: [🚗] Some message
            |> [INFO 02-21 15:16:18.189] FileName.swift - Function - line 42: Multiline Message:
                line 1
                line 2
                line 3
            |> [INFO 02-21 16:17:18.000] FileName2.swift - Function2 - line 43: Second log with special characters ::[]{}()//
            """

        let sut = LogEntryDecoder(
            logRecordSeparator: "|>",
            logHeaderOpeningSeparator: "[",
            logHeaderClosingSeparator: "]",
            logLocationSeparator: "-",
            lineIdentifier: "line",
            messageSeparator: ":",
            dateFormatter: DateFormatter.monthsDaysTimeFormatter
        )

        let result = try sut.decode(record)

        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0].body, """
            Multiline Message:
                line 1
                line 2
                line 3
            """
        )
        XCTAssertEqual(result[1].body, "[🚗] Some message")
        XCTAssertEqual(result[2].body, """
            Multiline Message:
                line 1
                line 2
                line 3
            """
        )
        XCTAssertEqual(result[3].body, "Second log with special characters ::[]{}()//")
    }
}
