import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        let chats = JournalStore(context: context).snapshot()
        List {
            Section("Export") {
                ShareLink(item: MarkdownExport(chats: chats), preview: SharePreview("btmx-log.md")) {
                    Label("Export to Markdown", systemImage: "doc.text")
                }
                .accessibilityIdentifier("exportMarkdown")
                ShareLink(item: JSONExport(chats: chats), preview: SharePreview("btmx-log.json")) {
                    Label("Export to JSON", systemImage: "curlybraces")
                }
                .accessibilityIdentifier("exportJSON")
            }
            Section("About") {
                LabeledContent("Version", value: AppInfo.version)
                LabeledContent("Commit", value: AppInfo.commit)
                    .accessibilityIdentifier("aboutCommit")
                LabeledContent("Author", value: AppInfo.author)
            }
        }
        .navigationTitle("Settings")
    }
}

enum AppInfo {
    static let author = "Mikhail Laptev"

    /// Marketing version and build number, for example "1.0 (1)".
    static var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let short = info["CFBundleShortVersionString"] as? String ?? "?"
        let build = info["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    /// Git commit the app was built from; "dev" when built from Xcode without the scripts.
    static var commit: String {
        Bundle.main.infoDictionary?["BtmxCommit"] as? String ?? "unknown"
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .modelContainer(try! JournalStore.makeContainer(inMemory: true))
}
