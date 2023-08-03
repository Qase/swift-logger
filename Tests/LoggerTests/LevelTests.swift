import XCTest
@testable import Logger

class LevelTests: XCTestCase {

    func test_mapping_from_raw_value() {
        XCTAssert(Level(rawValue: "debug") == .debug)
        XCTAssert(Level(rawValue: "info") == .info)
        XCTAssert(Level(rawValue: "default") == .default)
        XCTAssert(Level(rawValue: "warning") == .warning)
        XCTAssert(Level(rawValue: "critical") == .critical)
        XCTAssert(Level(rawValue: "aaa") == .custom("aaa"))
    }
}
