import SwiftUI

@main
struct TaskTrackerApp: App {
    @State private var store = Store()

    var body: some Scene {
        MenuBarExtra {
            TrackerView(store: store)
        } label: {
            MenuBarIcon()
        }
        .menuBarExtraStyle(.window)
    }
}
