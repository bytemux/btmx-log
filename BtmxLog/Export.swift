import CoreTransferable
import Foundation
import UniformTypeIdentifiers

nonisolated struct ExportedMessage: Codable, Equatable, Sendable {
    let id: UUID
    let text: String
    let date: Date
}

nonisolated struct ExportedChat: Codable, Equatable, Sendable {
    let id: UUID
    let title: String
    let createdAt: Date
    let messages: [ExportedMessage]
}

nonisolated enum Exporter {
    static func json(_ chats: [ExportedChat]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(chats)
    }

    /// One `#` section per chat, one `##` section per day, one line per message.
    static func markdown(_ chats: [ExportedChat], timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let day = Date.ISO8601FormatStyle(timeZone: timeZone).year().month().day()
        let time = Date.VerbatimFormatStyle(
            format: "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)",
            timeZone: timeZone,
            calendar: calendar
        )

        var lines = ["# btmx log export", ""]
        for chat in chats {
            lines += ["# \(chat.title)", ""]
            var currentDay: String?
            for message in chat.messages {
                let messageDay = message.date.formatted(day)
                if messageDay != currentDay {
                    lines += ["## \(messageDay)", ""]
                    currentDay = messageDay
                }
                let text = message.text.replacingOccurrences(of: "\n", with: "\n  ")
                lines.append("- \(message.date.formatted(time)) \(text)")
            }
            if !chat.messages.isEmpty { lines.append("") }
        }
        return lines.joined(separator: "\n")
    }
}

nonisolated struct JSONExport: Transferable {
    let chats: [ExportedChat]

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { try Exporter.json($0.chats) }
            .suggestedFileName("btmx-log.json")
    }
}

nonisolated struct MarkdownExport: Transferable {
    let chats: [ExportedChat]

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: UTType(filenameExtension: "md") ?? .plainText) {
            Data(Exporter.markdown($0.chats).utf8)
        }
        .suggestedFileName("btmx-log.md")
    }
}
