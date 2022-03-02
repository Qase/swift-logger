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
        let logEntryConfig = LogEntryConfig()
        let expectedDate = logEntryConfig.dateFormatter.date(from: "2022-02-21 15:16:17.189")
        let record = "|> [INFO 2022-02-21 15:16:17.189] FileName.swift — Function — line 42: Some log with special characters ::[]{}()//"

        let sut = LogEntryDecoder(logEntryConfig: logEntryConfig)

        let result = try sut.decode(record)

        XCTAssertEqual(result?.header.level.rawValue, "INFO")
        XCTAssertEqual(result?.header.date, expectedDate)
        XCTAssertEqual(result?.location.fileName, "FileName.swift")
        XCTAssertEqual(result?.location.function, "Function")
        XCTAssertEqual(result?.location.line, 42)
        XCTAssertEqual(result?.message.description, "Some log with special characters ::[]{}()//")
    }

    func test_sut_should_parse_first_line_only() throws {
        let logEntryConfig = LogEntryConfig()
        let expectedDate = logEntryConfig.dateFormatter.date(from: "2022-02-21 15:16:17.189")
        let record = """
            |> [INFO 2022-02-21 15:16:17.189] FileName.swift — Function — line 42: First log with special characters ::[]{}()//
            |> [INFO 2022-02-21 16:17:18.000] FileName2.swift — Function2 — line 43: Second log with special characters ::[]{}()//
            """

        let sut = LogEntryDecoder(logEntryConfig: logEntryConfig)

        let result = try sut.decode(record)

        XCTAssertEqual(result?.header.level.rawValue, "INFO")
        XCTAssertEqual(result?.header.date, expectedDate)
        XCTAssertEqual(result?.location.fileName, "FileName.swift")
        XCTAssertEqual(result?.location.function, "Function")
        XCTAssertEqual(result?.location.line, 42)
        XCTAssertEqual(result?.message.description, "First log with special characters ::[]{}()//")
    }

    func test_sut_should_parse_encoded_json() throws {
        let logEntryConfig = LogEntryConfig()
        let expectedDate = logEntryConfig.dateFormatter.date(from: "2022-02-21 15:16:17.189")
        let record = "|> [INFO 2022-02-21 15:16:17.189] FileName.swift — Function — line 42: {\"array\":[1,2,3],\"text\":\"Text\"}"

        let sut = LogEntryDecoder(logEntryConfig: logEntryConfig)

        let result = try sut.decode(record)

        XCTAssertEqual(result?.header.level.rawValue, "INFO")
        XCTAssertEqual(result?.header.date, expectedDate)
        XCTAssertEqual(result?.location.fileName, "FileName.swift")
        XCTAssertEqual(result?.location.function, "Function")
        XCTAssertEqual(result?.location.line, 42)
        XCTAssertEqual(result?.message.description, "{\"array\":[1,2,3],\"text\":\"Text\"}")
    }

    func test_sut_should_parse_line_with_an_emoji() throws {
        let logEntryConfig = LogEntryConfig()
        let expectedDate = logEntryConfig.dateFormatter.date(from: "2022-02-21 15:16:17.189")
        let record = "|> [INFO 2022-02-21 15:16:17.189] FileName.swift — Function — line 42: [🚗] Some message"

        let sut = LogEntryDecoder(logEntryConfig: logEntryConfig)

        let result = try sut.decode(record)

        XCTAssertEqual(result?.header.level.rawValue, "INFO")
        XCTAssertEqual(result?.header.date, expectedDate)
        XCTAssertEqual(result?.location.fileName, "FileName.swift")
        XCTAssertEqual(result?.location.function, "Function")
        XCTAssertEqual(result?.location.line, 42)
        XCTAssertEqual(result?.message.description, "[🚗] Some message")
    }

    func test_sut_should_parse_multiline_log() throws {
        let logEntryConfig = LogEntryConfig()
        let expectedDate = logEntryConfig.dateFormatter.date(from: "2022-02-21 15:16:17.189")
        let record = """
            |> [INFO 2022-02-21 15:16:17.189] FileName.swift — Function — line 42: Multiline Message:
                line 1
                line 2
                line 3
            """

        let sut = LogEntryDecoder(logEntryConfig: logEntryConfig)

        let result = try sut.decode(record)

        XCTAssertEqual(result?.header.level.rawValue, "INFO")
        XCTAssertEqual(result?.header.date, expectedDate)
        XCTAssertEqual(result?.location.fileName, "FileName.swift")
        XCTAssertEqual(result?.location.function, "Function")
        XCTAssertEqual(result?.location.line, 42)
        XCTAssertEqual(result?.message.description, """
            Multiline Message:
                line 1
                line 2
                line 3
            """
        )
    }
}
