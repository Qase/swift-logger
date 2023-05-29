//
//  File.swift
//  
//
//  Created by Martin Ficek on 29.05.2023.
//

import XCTest
@testable import Logger
import Combine

class LoggerManagerTests: XCTestCase {
// MARK: Commented code is used for testing failure of the previous FileManager, should be deleted before merge
//  private let appGroupID = "test-app-group-id"
//  private let namespace = "test-namespace"
//  private var fileManager: FileManager!
//  private var userDefaults: UserDefaults!
//  private var logDirURL: URL!
//
//  override func setUp() {
//      super.setUp()
//
//      self.fileManager = FileManager.default
//      self.userDefaults = UserDefaults(suiteName: appGroupID)!
//
//      self.logDirURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
//          .appendingPathComponent(namespace)
//  }
  
  func test_loggerManager_multithreading_delete_and_log_simultaneously() throws {
//    let fileLogger = try FileLogger(
//      appName: nil,
//      fileManager: fileManager,
//      userDefaults: userDefaults,
//      logDirURL: logDirURL,
//      namespace: nil,
//      numberOfLogFiles: 100,
//      dateFormatter: DateFormatter.dateFormatter,
//      fileHeaderContent: "",
//      lineSeparator: "<-->",
//      logEntryEncoder: LogEntryEncoder(),
//      logEntryDecoder: LogEntryDecoder(),
//      externalLogger: { _ in }
//    )
    
    let loggerManager = LoggerManager(loggers: .init())
    var cancellables = Set<AnyCancellable>()
    
    (1...100).publisher
      .flatMap { _ in
        Just(())
          .subscribe(on: DispatchQueue.global())
          .handleEvents(
            receiveOutput: {
              //              fileLogger.log(
              //               .init(
              //                header: .init(date: Date(), level: .info, dateFormatter: DateFormatter.dateTimeFormatter),
              //                 location: .init(fileName: "File", function: "function", line: 1),
              //                 message: "Error message"
              //               )
              //              )
              loggerManager.log("1", onLevel: Level(rawValue: "1"))
              print("log")
            }
          )
      }
      .collect(2)
      .map { _ in }
      .flatMap {
        Just(())
          .subscribe(on: DispatchQueue.global())
          .handleEvents(
            receiveOutput: {
              //              try? fileLogger.deleteAllLogFiles()
              loggerManager.deleteAllLogFiles()
              print("delete")
            }
          )
      }
      .sink { result in
        XCTAssertNotNil(result)
      }
      .store(in: &cancellables)
  }
}
