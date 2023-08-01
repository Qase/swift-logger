import SwiftUI

class ActionsViewModel: ObservableObject {
    let levels: [Level] = Level.allCases
    var logsType: [LogType] {
        levels.map(LogType.init)
    }

    init() {}

    func logTapped(level: Level) {
        log("\(level.rawValue)", onLevel: level)
    }
}

struct ActionsView: View {
    @ObservedObject var viewModel: ActionsViewModel

    var body: some View {
        NavigationView {
            logsList
                .navigationTitle("Log actions")
        }
    }

    var logsList: some View {
        List {
            ForEach(viewModel.logsType) {
                logButtonFactory(logType: $0)
            }
        }
    }

    private func logButtonFactory(logType: LogType) -> some View {
        Button {
            viewModel.logTapped(level: logType.level)
        } label: {
            Text("Log \(logType.level.rawValue.uppercased())")
        }
    }
}
