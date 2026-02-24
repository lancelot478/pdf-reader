import SwiftUI

@main
struct StickyNotesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 700, height: 500)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
