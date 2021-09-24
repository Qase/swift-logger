//
//  WebLogger.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

// TODO: Refactor using Combine instead of RxSwift

import Foundation
//import RxSwift
//
//struct LogEntry: JSONSerializable {
//    let level: Level
//    let timestamp: Double
//    let message: String
//    let sessionName: String
//
//    var jsonRepresentation: AnyObject {
//        [
//            "severity": serverLevelName(for: level),
//            "timestamp": timestamp,
//            "message": message,
//            "sessionName": sessionName
//        ] as AnyObject
//    }
//
//    private func serverLevelName(for level: Level) -> String {
//        switch level {
//        case .warn:
//            return "WARNING"
//        case .system, .process:
//            return "INFO"
//        default:
//            return level.rawValue.uppercased()
//        }
//    }
//}
//
//struct LogEntryBatch: JSONSerializable {
//    private var logs: [LogEntry]
//
//    init(logs: [LogEntry] = []) {
//        self.logs = logs
//    }
//
//    mutating func add(log: LogEntry) {
//        logs.append(log)
//    }
//
//    mutating func clearLogs() {
//        logs = []
//    }
//
//    var jsonRepresentation: AnyObject {
//        logs.jsonRepresentation
//    }
//
//}
//
//public class WebLogger: Logging {
//    // Default value is UUID which is same until someone reinstal the application
//    private let sessionName: String
//
//    // Size of batch which is send to server API
//    // In other word, lengt of array whith LogEntries
//    private let sizeOfBatch: Int
//
//    // After this time interval LogEntries are send to server API, regardless of their amount
//    private let timeSpan: RxTimeInterval
//
//    public static let defaultServerUrl = "http://localhost:3000/api/v1"
//
//    private let api: WebLoggerApi?
//
//    private let logSubject = ReplaySubject<LogEntry>.create(bufferSize: 10)
//
//    private let bag = DisposeBag()
//
//    public init(serverUrl: String = WebLogger.defaultServerUrl,
//                apiPath: String = "/api/v1",
//                sessionName: String = UUID().uuidString,
//                sizeOfBatch: Int = 5,
//                timeSpan: RxTimeInterval = .seconds(4)) {
//
//        let serverUrlHasScheme = serverUrl.starts(with: "http://") || serverUrl.starts(with: "https://")
//        self.api = WebLoggerApi(url: (serverUrlHasScheme ? "" : "http://") + serverUrl + apiPath)
//        self.sessionName = sessionName
//        self.sizeOfBatch = sizeOfBatch
//        self.timeSpan = timeSpan
//    }
//
//    open func configure() {
//        logSubject
//            .buffer(timeSpan: timeSpan, count: sizeOfBatch, scheduler: MainScheduler.instance)
//            .filter { $0.count > 0 }
//            .map { LogEntryBatch(logs: $0) }
//            .flatMap { logBatch -> Completable in
//                guard let _api = self.api else {
//                    return Completable.error(WebLoggerApiError.invalidUrl)
//                }
//
//                return _api.send(logBatch)
//            }
//            .subscribe()
//            .disposed(by: bag)
//
//    }
//
//    public var levels: [Level] = [.info]
//
//    open func log(_ message: String, onLevel level: Level) {
//        //do some fancy logging
//
//        let entry = LogEntry(level: level, timestamp: Date().timeIntervalSince1970 * 1000, message: message, sessionName: sessionName)
//        logSubject.onNext(entry)
//    }
//}
