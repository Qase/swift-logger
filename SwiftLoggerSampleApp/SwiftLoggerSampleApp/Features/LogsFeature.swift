import Combine
import Logger
import OSLog
import SwiftUI

class LogsViewModel: ObservableObject {

    enum LogsSource: String, Hashable, CaseIterable {
        case fileLogger = "File logger"
        case nativeLogger = "Native logger"
    }

    @Published var logsState: Loadable<[CellViewModel], AppError> = .idle
    @Published var logsSource: LogsSource = .nativeLogger

    var logs: [CellViewModel] {
        get {
            guard case let .loaded(logs) = logsState else {
                return []
            }
            return logs
        }
        set {
            guard case .loaded = logsState else {
                return
            }

            logsState = .loaded(newValue)
        }
    }
    private var cancellables: Set<AnyCancellable> = []

    init() {
        $logsSource
            .dropFirst()
            .sink { _ in
                Task {
                    await self.retrieveLogs()
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    func retrieveLogs() async {
        logsState = .loading

        switch logsSource {
        case .fileLogger:
            do {
                let cellsViewModel = try logRecordsFromFileLogger()
                    .map(CellViewModel.init)
                logsState = .loaded(cellsViewModel)
            } catch {
                logsState = .failure(AppError(error: error))
            }

        case .nativeLogger:
            do {
                let cellsViewModel = try await getEntriesFromLogStore()
                    .map(CellViewModel.init)
                logsState = .loaded(cellsViewModel)
            } catch {
                logsState = .failure(AppError(error: error))
            }
        }

        return
    }

    private func logRecordsFromFileLogger() throws -> [String] {
        log("Start getting logs from file logger", onLevel: .info)

        guard let logRecords = fileLogger?.logRecords() else {
            throw OSLogError.logRecordsFailed
        }

        return logRecords
            .map { LogEntryEncoder().encode($0, verbose: true) }
    }

    private func getEntriesFromLogStore() async throws -> [String] {
        log("Start getting entries from log store", onLevel: .info)
        let store = try OSLogStore.getOsLogStore()
        return try await store.getEntries()
            .map { $0.formatted }
    }
}

struct LogsView: View {
    @ObservedObject var viewModel: LogsViewModel

    var body: some View {
        NavigationView {
            VStack {
                picker

                Spacer()
                content
                Spacer()
            }
            .navigationTitle("Logs history")
            .task {
                await viewModel.retrieveLogs()
            }
        }
    }

    var picker: some View {
        Picker("Choose a logs source", selection: $viewModel.logsSource) {
            ForEach(LogsViewModel.LogsSource.allCases, id: \.self) { element in
                Text(element.rawValue)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    var content: some View {
        switch viewModel.logsState {
        case .idle:
            ProgressView()

        case .loading:
            ProgressView {
                Text("Loading ...")
            }

        case .loaded:
            logsList

        case let .failure(error):
            Text("Error - \(error.localizedDescription)")
        }
    }

    var logsList: some View {
        VStack(spacing: 10) {
            if viewModel.logs.isEmpty {
                Text("No logs")
            } else {
                Text("Number of logs: \(viewModel.logs.count)")

                List {
                    ForEach(viewModel.logs) { cellViewModel in
                        CellView(viewModel: cellViewModel)
                    }
                }
            }
        }
    }
}

struct LogsView_Previews: PreviewProvider {
    static var previews: some View {
        LogsView(viewModel: LogsViewModel())
    }
}
