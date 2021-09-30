//
//  SendLogsView.swift
//  
//
//  Created by Alžbeta Gogoláková on 18.08.2021.
//

#if canImport(SwiftUI) && canImport(MessageUI) && !os(macOS)
import MessageUI
import SwiftUI

public typealias MailViewCallback = ((Result<MFMailComposeResult, Error>) -> Void)?

@available(iOS 13.0, *)
public struct SendMailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentation
    let data: MailData
    private let callback: MailViewCallback

    public init(
        data: MailData,
        callback: MailViewCallback
    ) {
        self.data = data
        self.callback = callback
    }

    public class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var presentation: PresentationMode
        let data: MailData
        private let callback: MailViewCallback

        public init(
            presentation: Binding<PresentationMode>,
            data: MailData,
            callback: MailViewCallback
        ) {
            _presentation = presentation
            self.data = data
            self.callback = callback
        }

        public func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            if let error = error {
                callback?(.failure(error))
            } else {
                callback?(.success(result))
            }
            $presentation.wrappedValue.dismiss()
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(presentation: presentation, data: data, callback: callback)
    }

    public func makeUIViewController(context: UIViewControllerRepresentableContext<SendMailView>) -> MFMailComposeViewController {
        let viewController = MFMailComposeViewController()
        viewController.mailComposeDelegate = context.coordinator
        viewController.setSubject(data.subject)
        viewController.setToRecipients(data.recipients)
        viewController.setMessageBody(data.message, isHTML: false)
        data.attachments?.forEach {
            viewController.addAttachmentData($0.data, mimeType: $0.mimeType, fileName: $0.fileName)
        }
        viewController.accessibilityElementDidLoseFocus()

        return viewController
    }

    public func updateUIViewController(
        _ uiViewController: MFMailComposeViewController,
        context: UIViewControllerRepresentableContext<SendMailView>) {
    }

    static var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }
}
#endif
