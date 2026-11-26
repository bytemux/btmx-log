import SwiftData
import SwiftUI

@main
struct BtmxLogApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try JournalStore.makeContainer()
        } catch {
            fatalError("Cannot open the journal store: \(error)")
        }
        JournalStore(context: container.mainContext).ensureInbox()
    }

    var body: some Scene {
        WindowGroup {
            ChatListView()
                .preferredColorScheme(.light)
        }
        .modelContainer(container)
    }
}
