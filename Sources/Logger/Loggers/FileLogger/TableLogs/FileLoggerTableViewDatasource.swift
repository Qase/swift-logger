//
//  FileLoggerTableViewDatasource.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

// TODO: Refactor using SwiftUI instead of UIKit

#if canImport(UIKit)
import UIKit

open class FileLoggerTableViewDatasource: NSObject, UITableViewDataSource {

    public var logFilesRecords = [LogFileRecord]()

    public override init() {
        super.init()

        reloadLogFilesRecords()
    }

    open func gettingCell(_ tableView: UITableView, forRowAt indexPath: IndexPath, withLogFileRecord: LogFileRecord) -> UITableViewCell {
        let identifier = Constants.FileLoggerTableViewDatasource.fileLoggerTableViewCellIdentifier
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? FileLoggerTableViewCell else {
            return UITableViewCell()
        }

        cell.logFileRecord = logFilesRecords[indexPath.row]
        return cell
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        gettingCell(tableView, forRowAt: indexPath, withLogFileRecord: logFilesRecords[indexPath.row])
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        logFilesRecords.count
    }

    public func reload() {
        reloadLogFilesRecords()
    }

    private func reloadLogFilesRecords() {
        var _logFilesRecords = [LogFileRecord]()
        let fileLoggerManager = FileLoggerManager.shared
        if let _logDirUrl = fileLoggerManager.logDirUrl {
            for index in 0..<fileLoggerManager.numOfLogFiles {
                let logFileNumber = (fileLoggerManager.currentLogFileNumber + index) % fileLoggerManager.numOfLogFiles
                let logFileUrl = _logDirUrl.appendingPathComponent("\(logFileNumber)").appendingPathExtension("log")

                let logFileRecords = fileLoggerManager.gettingRecordsFromLogFile(at: logFileUrl)
                if let _logFileRecords = logFileRecords {
                    _logFilesRecords.append(contentsOf: _logFileRecords)
                }
            }
        }

        logFilesRecords = _logFilesRecords
    }
}
#endif
