//
//  FileLogsTable.swift
//  SwiftLoggerSampleApp
//
//  Created by Dagy Tran on 28.09.2021.
//

import Logger
import SwiftUI

struct FileLogsTable: View {
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                let logRecords = fileLogger.logRecords() ?? []
                let logEntryEncoder = LogEntryEncoder()

                ForEach(Array(zip(logRecords.indices, logRecords)), id: \.0) { _, logEntry in
                    Text(logEntryEncoder.encode(logEntry, verbose: false))
                }
            }
            .padding()
        }
        .navigationTitle("File logs")
    }
}

struct FileLogsTable_Previews: PreviewProvider {
    static var previews: some View {
        FileLogsTable()
    }
}
