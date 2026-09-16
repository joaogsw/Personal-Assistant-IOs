import SwiftUI

@main
struct PersonalAssistantApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootTabView(container: container)
        }
    }
}
