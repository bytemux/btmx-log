import Foundation
import SwiftData
import Testing
@testable import BtmxLog

@MainActor
struct JournalStoreTests {
    private let container = try! JournalStore.makeContainer(inMemory: true)
    private var store: JournalStore { JournalStore(context: container.mainContext) }

    @Test func createsInboxOnce() throws {
        let first = store.ensureInbox()
        let second = store.ensureInbox()
        #expect(first.id == second.id)
        #expect(first.title == "Inbox")
        let chats = try container.mainContext.fetch(FetchDescriptor<Chat>())
        #expect(chats.count == 1)
    }

    @Test func keepsMessageAtExactLimit() throws {
        let text = String(repeating: "a", count: JournalStore.characterLimit)
        let message = try #require(store.send(text, to: store.ensureInbox()))
        #expect(message.text.count == 4_096)
    }

    @Test func cutsMessageOverLimit() throws {
        let text = String(repeating: "b", count: JournalStore.characterLimit + 1)
        let message = try #require(store.send(text, to: store.ensureInbox()))
        #expect(message.text.count == 4_096)
    }

    @Test func rejectsWhitespaceOnly() {
        let inbox = store.ensureInbox()
        #expect(store.send(" \n\t ", to: inbox) == nil)
        #expect(inbox.messages?.isEmpty == true)
        #expect(store.createChat(title: "   ") == nil)
    }

    @Test func messageGoesToItsChatAndBumpsIt() throws {
        let inbox = store.ensureInbox()
        let sport = try #require(store.createChat(title: "  Sport  ", date: Date(timeIntervalSince1970: 0)))
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        store.send("Ran 5 km", to: sport, date: date)

        #expect(sport.title == "Sport")
        #expect(sport.messages?.map(\.text) == ["Ran 5 km"])
        #expect(inbox.messages?.isEmpty == true)
        #expect(sport.updatedAt == date)
    }

    @Test func savesToDiskAndReloads() throws {
        let url = URL.temporaryDirectory.appending(path: "journal-\(UUID().uuidString).store")
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        do {
            let container = try ModelContainer(for: Chat.self, Message.self, configurations: ModelConfiguration(url: url))
            let store = JournalStore(context: container.mainContext)
            store.send("Saved", to: store.ensureInbox(), date: date)
        }
        let reloaded = try ModelContainer(for: Chat.self, Message.self, configurations: ModelConfiguration(url: url))
        let message = try #require(try reloaded.mainContext.fetch(FetchDescriptor<Message>()).first)
        #expect(message.text == "Saved")
        #expect(message.date == date)
        #expect(message.chat?.isInbox == true)
    }
}
