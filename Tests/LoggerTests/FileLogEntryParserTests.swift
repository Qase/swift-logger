//
//  FileLogEntryParserTests.swift
//  
//
//  Created by Radek Čep on 22.02.2022.
//

import XCTest
@testable import Logger

class FileLogEntryParserTests: XCTestCase {
    func test_sut_should_parse_line() throws {
        let dateFormatter = DateFormatter.monthsDaysTimeFormatter
        let expectedDate = dateFormatter.date(from: "02-21 15:47:58.546")
        let record = "|> [INFO 02-21 15:47:58.546] Root+loggingReducer.swift - Root - line 28: AppConfiguration languageCode: cs"

        let sut = FileLogEntryParser(
            logFileRecordSeparator: "|>",
            logHeaderOpeningSeparator: "[",
            logHeaderClosingSeparator: "]",
            logLocationSeparator: "-",
            lineIdentifier: "line",
            messageSeparator: ":"
        )

        let result = try sut.parse(record, dateFormatter: dateFormatter)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.header.level.rawValue, "INFO")
        XCTAssertEqual(result?.header.date, expectedDate)
        XCTAssertEqual(result?.location.fileName, "Root+loggingReducer.swift")
        XCTAssertEqual(result?.location.function, "Root")
        XCTAssertEqual(result?.location.line, 28)
        XCTAssertEqual(result?.body, "AppConfiguration languageCode: cs")
    }

    func test_sut_should_parse_encoded_json() throws {
        let dateFormatter = DateFormatter.monthsDaysTimeFormatter
        let expectedDate = dateFormatter.date(from: "02-21 15:47:58.624")
        let record = "|> [INFO 02-21 15:47:58.624] AppSetupCore.swift - AppSetup - line 68: {\"array\":[1,2,3],\"text\":\"Text\"}"

        let sut = FileLogEntryParser(
            logFileRecordSeparator: "|>",
            logHeaderOpeningSeparator: "[",
            logHeaderClosingSeparator: "]",
            logLocationSeparator: "-",
            lineIdentifier: "line",
            messageSeparator: ":"
        )

        let result = try sut.parse(record, dateFormatter: dateFormatter)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.header.level.rawValue, "INFO")
        XCTAssertEqual(result?.header.date, expectedDate)
        XCTAssertEqual(result?.location.fileName, "AppSetupCore.swift")
        XCTAssertEqual(result?.location.function, "AppSetup")
        XCTAssertEqual(result?.location.line, 68)
        XCTAssertEqual(result?.body, "{\"array\":[1,2,3],\"text\":\"Text\"}")
    }

    func test_sut_should_parse_line_with_an_emoji() throws {
        let dateFormatter = DateFormatter.monthsDaysTimeFormatter
        let expectedDate = dateFormatter.date(from: "02-21 15:47:58.546")
        let record = "|> [INFO 02-21 15:47:58.546] Root+loggingReducer.swift - Root - line 28: [🚗] AppConfiguration languageCode: cs"

        let sut = FileLogEntryParser(
            logFileRecordSeparator: "|>",
            logHeaderOpeningSeparator: "[",
            logHeaderClosingSeparator: "]",
            logLocationSeparator: "-",
            lineIdentifier: "line",
            messageSeparator: ":"
        )

        let result = try sut.parse(record, dateFormatter: dateFormatter)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.header.level.rawValue, "INFO")
        XCTAssertEqual(result?.header.date, expectedDate)
        XCTAssertEqual(result?.location.fileName, "Root+loggingReducer.swift")
        XCTAssertEqual(result?.location.function, "Root")
        XCTAssertEqual(result?.location.line, 28)
        XCTAssertEqual(result?.body, "[🚗] AppConfiguration languageCode: cs")
    }

    func test_sut_should_parse_multiline_log() throws {
        let dateFormatter = DateFormatter.monthsDaysTimeFormatter
        let expectedDate = dateFormatter.date(from: "02-21 15:48:07.570")
        let record = """
            |> [INFO 02-21 15:48:07.570] Root+loggingReducer.swift - Root - line 72: AppDelegate userNotifications willPresentNotification with userInfo: [AnyHashable("aps"): {
                alert =     {
                    "loc-args" =         (
                        TMBJW9NX6MY000136,
                        "Moje Auto",
                        ZoNa
                    );
                    "loc-key" = "batterycoldwarning_climatisation";
                };
                sound =     {
                    name = default;
                };
            }]
            """

        let sut = FileLogEntryParser(
            logFileRecordSeparator: "|>",
            logHeaderOpeningSeparator: "[",
            logHeaderClosingSeparator: "]",
            logLocationSeparator: "-",
            lineIdentifier: "line",
            messageSeparator: ":"
        )

        let result = try sut.parse(record, dateFormatter: dateFormatter)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.header.level.rawValue, "INFO")
        XCTAssertEqual(result?.header.date, expectedDate)
        XCTAssertEqual(result?.location.fileName, "Root+loggingReducer.swift")
        XCTAssertEqual(result?.location.function, "Root")
        XCTAssertEqual(result?.location.line, 72)
        XCTAssertEqual(result?.body, """
            AppDelegate userNotifications willPresentNotification with userInfo: [AnyHashable("aps"): {
                alert =     {
                    "loc-args" =         (
                        TMBJW9NX6MY000136,
                        "Moje Auto",
                        ZoNa
                    );
                    "loc-key" = "batterycoldwarning_climatisation";
                };
                sound =     {
                    name = default;
                };
            }]
            """
        )
    }
}
