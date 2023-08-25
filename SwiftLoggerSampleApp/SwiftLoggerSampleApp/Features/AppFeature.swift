import SwiftUI

class AppViewModel: ObservableObject {
    let actionViewModel = ActionsViewModel()
    let logsViewModel = LogsViewModel()
    let settingsViewModel = SettingsViewModel()

    init() {}
}

struct AppView: View {

    enum Tab: String, Equatable, Hashable {
        case actions, logs, settings

        var icon: some View {
            switch self {
            case .actions:
                return Image(systemName: "command")

            case .logs:
                return Image(systemName: "list.bullet")

            case .settings:
                return Image(systemName: "gear")
            }
        }
    }

    @ObservedObject var viewModel: AppViewModel
    @State var selectedTab: Tab

    var body: some View {
        TabView {
            ActionsView(viewModel: viewModel.actionViewModel)
                .tabItem { tabItem(for: .actions) }
                .tag(Tab.actions.rawValue)

            LogsView(viewModel: viewModel.logsViewModel)
                .tabItem { tabItem(for: .logs) }
                .tag(Tab.logs.rawValue)

            SettingsView(viewModel: viewModel.settingsViewModel)
                .tabItem { tabItem(for: .settings) }
                .tag(Tab.settings.rawValue)
        }
    }

    func tabItem(for tab: Tab) -> some View {
        Label {
            Text(tab.rawValue)
        } icon: {
            tab.icon
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(viewModel: AppViewModel(), selectedTab: .actions)
    }
}
