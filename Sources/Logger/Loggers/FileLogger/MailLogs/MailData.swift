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

extension AttachmentData {
    init?(fromURL url: URL, data: Data) {
        self.data = data
        self.mimeType = "text/plain"
        self.fileName = url.lastPathComponent
    }
}

// MARK: - MailData

public extension MailData {
    static func withLogsAsAttachments(
        perLogFileData: [URL: Data],
        subject: String,
        recipients: [String]?, message: String
    ) -> MailData {
        MailData(
            subject: subject,
            recipients: recipients,
            message: message,
            attachments: {
                perLogFileData.compactMap { AttachmentData(fromURL: $0.key, data: $0.value) }
            }()
        )
    }
}
