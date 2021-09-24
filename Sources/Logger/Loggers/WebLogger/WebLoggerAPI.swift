//
//  WebLoggerAPI.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

// TODO: Refactor using Combine instead of RxSwift

import Foundation
//import RxSwift
//
//protocol WebLoggerApiType {
//    func send(_ logBatch: LogEntryBatch) -> Completable
//}
//
//enum WebLoggerApiError: Error {
//    case invalidUrl
//}
//
//class WebLoggerApi: BaseApi {
//
//}
//
//extension WebLoggerApi: WebLoggerApiType {
//    func send(_ logBatch: LogEntryBatch) -> Completable {
//        let request = ApiFactory.buildRequest(baseUrl: url, pathComponent: "log", method: .post, withJsonBody: logBatch.jsonData)
//
//        return ApiFactory.noData(for: request, in: session).ignoreElements()
//    }
//}
