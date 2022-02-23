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
            logFileRecordSeparator: "|>",
            logHeaderOpeningSeparator: "[",
            logHeaderClosingSeparator: "]",
            logLocationSeparator: "-",
            lineIdentifier: "line",
            messageSeparator: ":",
            dateFormatter: dateFormatter
        )

        let result = try sut.decode(record)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.header.level.rawValue, "INFO")
        XCTAssertEqual(result?.header.date, expectedDate)
        XCTAssertEqual(result?.location.fileName, "FileName.swift")
        XCTAssertEqual(result?.location.function, "Function")
        XCTAssertEqual(result?.location.line, 42)
        XCTAssertEqual(result?.body, "Some log with special characters ::[]{}()//")
    }

    func test_sut_should_parse_encoded_json() throws {
        let dateFormatter = DateFormatter.monthsDaysTimeFormatter
        let expectedDate = dateFormatter.date(from: "02-21 15:16:17.189")
        let record = "|> [INFO 02-21 15:16:17.189] FileName.swift - Function - line 42: {\"array\":[1,2,3],\"text\":\"Text\"}"

        let sut = LogEntryDecoder(
            logFileRecordSeparator: "|>",
            logHeaderOpeningSeparator: "[",
            logHeaderClosingSeparator: "]",
            logLocationSeparator: "-",
            lineIdentifier: "line",
            messageSeparator: ":",
            dateFormatter: dateFormatter
        )

        let result = try sut.decode(record)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.header.level.rawValue, "INFO")
        XCTAssertEqual(result?.header.date, expectedDate)
        XCTAssertEqual(result?.location.fileName, "FileName.swift")
        XCTAssertEqual(result?.location.function, "Function")
        XCTAssertEqual(result?.location.line, 42)
        XCTAssertEqual(result?.body, "{\"array\":[1,2,3],\"text\":\"Text\"}")
    }

    func test_sut_should_parse_line_with_an_emoji() throws {
        let dateFormatter = DateFormatter.monthsDaysTimeFormatter
        let expectedDate = dateFormatter.date(from: "02-21 15:16:17.189")
        let record = "|> [INFO 02-21 15:16:17.189] FileName.swift - Function - line 42: [🚗] Some message"

        let sut = LogEntryDecoder(
            logFileRecordSeparator: "|>",
            logHeaderOpeningSeparator: "[",
            logHeaderClosingSeparator: "]",
            logLocationSeparator: "-",
            lineIdentifier: "line",
            messageSeparator: ":",
            dateFormatter: dateFormatter
        )

        let result = try sut.decode(record)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.header.level.rawValue, "INFO")
        XCTAssertEqual(result?.header.date, expectedDate)
        XCTAssertEqual(result?.location.fileName, "FileName.swift")
        XCTAssertEqual(result?.location.function, "Function")
        XCTAssertEqual(result?.location.line, 42)
        XCTAssertEqual(result?.body, "[🚗] Some message")
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
            logFileRecordSeparator: "|>",
            logHeaderOpeningSeparator: "[",
            logHeaderClosingSeparator: "]",
            logLocationSeparator: "-",
            lineIdentifier: "line",
            messageSeparator: ":",
            dateFormatter: dateFormatter
        )

        let result = try sut.decode(record)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.header.level.rawValue, "INFO")
        XCTAssertEqual(result?.header.date, expectedDate)
        XCTAssertEqual(result?.location.fileName, "FileName.swift")
        XCTAssertEqual(result?.location.function, "Function")
        XCTAssertEqual(result?.location.line, 42)
        XCTAssertEqual(result?.body, """
            Multiline Message:
                line 1
                line 2
                line 3
            """
        )
    }
}
