//
//  FileLogsTable.swift
//  SwiftLoggerSampleApp
//
//  Created by Dagy Tran on 28.09.2021.
//

import Logger
import SwiftUI

struct FileLogsTable: View {
    let fileLogger = FileLogger()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(fileLogger.logFilesRecords, id: \.self) { log in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(log.header)
                            .font(Font.headline)
                        Text(log.body)
                            .font(Font.body)
                    }
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

extension LogFileRecord: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(header)
        hasher.combine(body)
    }

    public static func == (lhs: LogFileRecord, rhs: LogFileRecord) -> Bool {
        lhs.header == rhs.header && lhs.body == rhs.body
    }
}
