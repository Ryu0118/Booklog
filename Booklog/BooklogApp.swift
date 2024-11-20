import SwiftUI
import SwiftData

@main
struct BooklogApp: App {
    var sharedModelContainer: ModelContainer = {
        let modelConfiguration = ModelConfiguration(schema: BooklogConst.schema(), isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: BooklogConst.schema(), configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            GeometryReader { proxy in
                ContentView()
                    .environment(\.mainWindowSize, proxy.size)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
