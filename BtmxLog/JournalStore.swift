import Foundation
import SwiftData

/// All writes to the journal go through here, so views and tests share the same rules.
struct JournalStore {
    static let characterLimit = 4_096
    static let titleLimit = 64
    static let inboxTitle = "Inbox"
    /// Launch argument used by UI tests to start with an empty journal.
    static let resetArgument = "-resetStorage"

    let context: ModelContext

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([Chat.self, Message.self])
        if inMemory {
            return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
        let url = URL.applicationSupportDirectory.appending(path: "btmx-log.store")
        if ProcessInfo.processInfo.arguments.contains(resetArgument) {
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(at: URL(filePath: url.path(percentEncoded: false) + suffix))
            }
        }
        // `.automatic` syncs through CloudKit once the app has the iCloud entitlement;
        // without it (no Apple developer team yet) the store stays local.
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .automatic)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    /// Returns the Inbox chat, creating it on first launch.
    /// With iCloud sync, two devices can each create one; see README, "duplicate Inbox".
    @discardableResult
    func ensureInbox() -> Chat {
        let descriptor = FetchDescriptor<Chat>(
            predicate: #Predicate { $0.isInbox },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        if let inbox = try? context.fetch(descriptor).first {
            return inbox
        }
        let inbox = Chat(title: Self.inboxTitle, isInbox: true)
        context.insert(inbox)
        save()
        return inbox
    }

    /// Creates a chat. Returns nil when the title is empty after trimming.
    @discardableResult
    func createChat(title rawTitle: String, date: Date = .now) -> Chat? {
        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }
        let chat = Chat(title: String(title.prefix(Self.titleLimit)), date: date)
        context.insert(chat)
        save()
        return chat
    }

    /// Adds a message to a chat. Returns nil when the text is empty after trimming.
    @discardableResult
    func send(_ rawText: String, to chat: Chat, date: Date = .now) -> Message? {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let message = Message(text: String(trimmed.prefix(Self.characterLimit)), date: date, chat: chat)
        context.insert(message)
        chat.updatedAt = max(chat.updatedAt, date)
        save()
        return message
    }

    /// Plain copy of all chats and messages, oldest first, for export.
    func snapshot() -> [ExportedChat] {
        let chats = (try? context.fetch(FetchDescriptor<Chat>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        return chats.map { chat in
            ExportedChat(
                id: chat.id,
                title: chat.title,
                createdAt: chat.createdAt,
                messages: (chat.messages ?? [])
                    .sorted { $0.date < $1.date }
                    .map { ExportedMessage(id: $0.id, text: $0.text, date: $0.date) }
            )
        }
    }

    private func save() {
        do {
            try context.save()
        } catch {
            print("JournalStore: save failed: \(error)")
        }
    }
}
