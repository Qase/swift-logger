import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var logFilesURL: [URL]?

    func getLogFilesURL() {
        logFilesURL = try? fileLogger?.logFiles
    }

    func deleteAllLogs() {
        fileLogger?.deleteAllLogFiles()
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationView {
            list
                .onAppear {
                    viewModel.getLogFilesURL()
                }
        }
    }

    var list: some View {
        List {
            Section("File logger") {
                if #available(iOS 16.0, *) {
                    shareLink
                }

                Button {
                    viewModel.deleteAllLogs()
                } label: {
                    Text("Delete all logs")
                }
            }
        }
        .navigationTitle("Settings")
    }

    @available(iOS 16.0, *)
    @ViewBuilder
    var shareLink: some View {
        if let logFilesURL = viewModel.logFilesURL {
            ShareLink("Share log files", items: logFilesURL)
        } else {
            Text("Couldn't get log files url")
        }
    }
}
