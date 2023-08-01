import SwiftUI

@main
struct SwiftLoggerSampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            AppView(
                viewModel: AppViewModel(),
                selectedTab: .actions
            )
        }
    }
}
