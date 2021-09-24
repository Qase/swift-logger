//
//  MailData.swift
//  
//
//  Created by Alžbeta Gogoláková on 18.08.2021.
//

import Foundation

public struct MailData {
    public let subject: String
    public let recipients: [String]?
    public let message: String
    public let attachments: [AttachmentData]?
}

public struct AttachmentData {
    public let data: Data
    public let mimeType: String
    public let fileName: String
}

// MARK: - MailData

public extension MailData {
    static func withLogsAsAttachments(subject: String, recipients: [String]?, message: String) -> MailData {
        MailData(
            subject: subject,
            recipients: recipients,
            message: message,
            attachments: {
                guard let logFilesUrls = FileLoggerManager.shared.gettingAllLogFiles() else { return nil }
                return logFilesUrls.compactMap { logFileUrl in
                    guard let logFileContent = FileLoggerManager.shared.readingContentFromLogFile(at: logFileUrl) else {
                        return nil
                    }
                    guard let logFileData = logFileContent.data(using: .utf8) else {
                        return nil
                    }

                    return AttachmentData(data: logFileData, mimeType: "text/plain", fileName: logFileUrl.lastPathComponent)
                }
            }()
        )
    }
}
