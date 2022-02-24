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
            LazyVStack(alignment: .leading) {
                ForEach(fileLogger.logRecords() ?? [], id: \.self) { log in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(log.header.description)
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
