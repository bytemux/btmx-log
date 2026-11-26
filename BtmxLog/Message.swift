import Foundation
import SwiftData

// Models follow CloudKit rules: every property has a default, relationships are optional,
// no unique constraints. This keeps iCloud sync a configuration change, not a migration.

@Model
final class Chat {
    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date.now
    /// Time of the last message, or `createdAt`. The chat list sorts by it.
    var updatedAt: Date = Date.now
    /// The default chat for messages without a chosen chat.
    var isInbox: Bool = false
    @Relationship(deleteRule: .cascade, inverse: \Message.chat)
    var messages: [Message]? = []

    init(title: String, isInbox: Bool = false, date: Date = .now) {
        self.title = title
        self.isInbox = isInbox
        self.createdAt = date
        self.updatedAt = date
    }

    /// Newest message, for the chat list preview.
    var lastMessage: Message? {
        messages?.max { $0.date < $1.date }
    }
}

@Model
final class Message {
    var id: UUID = UUID()
    var text: String = ""
    var date: Date = Date.now
    var chat: Chat?

    init(text: String, date: Date, chat: Chat) {
        self.text = text
        self.date = date
        self.chat = chat
    }
}
