import Foundation
import Testing
@testable import BtmxLog

struct ExportTests {
    private let chats = [
        ExportedChat(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            title: "Inbox",
            createdAt: Date(timeIntervalSince1970: 0),
            messages: [
                ExportedMessage(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                    text: "First line\nsecond line 🙂",
                    date: Date(timeIntervalSince1970: 1_800_000_000)
                )
            ]
        )
    ]

    @Test func markdownGroupsByChatAndDay() {
        let markdown = Exporter.markdown(chats, timeZone: TimeZone(identifier: "UTC")!)
        #expect(markdown.contains("# Inbox"))
        #expect(markdown.contains("## 2027-01-15"))
        #expect(markdown.contains("- 08:00 First line\n  second line 🙂"))
    }

    @Test func jsonRoundTrips() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([ExportedChat].self, from: Exporter.json(chats))
        #expect(decoded == chats)
    }
}
