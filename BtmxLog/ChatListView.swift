import SwiftData
import SwiftUI

/// Screen 1: all chats, Inbox on top, the rest by last activity, like Telegram.
struct ChatListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Chat.updatedAt, order: .reverse) private var chats: [Chat]
    @State private var path: [Chat] = []
    @State private var search = ""
    @State private var isCreating = false
    @State private var newTitle = ""

    private var visibleChats: [Chat] {
        let sorted = chats.filter(\.isInbox) + chats.filter { !$0.isInbox }
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return sorted }
        return sorted.filter { $0.title.localizedStandardContains(query) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            List(visibleChats) { chat in
                NavigationLink(value: chat) {
                    ChatRow(chat: chat)
                }
                .accessibilityIdentifier("chatRow-\(chat.title)")
            }
            .listStyle(.plain)
            .overlay {
                if visibleChats.isEmpty, !search.isEmpty {
                    ContentUnavailableView.search(text: search)
                }
            }
            .searchable(text: $search, prompt: "Search chats")
            .navigationTitle("Chats")
            .navigationDestination(for: Chat.self) { ChatView(chat: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier("settingsButton")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newTitle = ""
                        isCreating = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New chat")
                    .accessibilityIdentifier("newChatButton")
                }
            }
            .alert("New chat", isPresented: $isCreating) {
                TextField("Name", text: $newTitle)
                Button("Cancel", role: .cancel) {}
                Button("Create", action: create)
                    .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func create() {
        if let chat = JournalStore(context: context).createChat(title: newTitle) {
            path.append(chat)
        }
    }
}

struct ChatRow: View {
    let chat: Chat

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: chat.isInbox ? "tray.fill" : "bubble.left.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(chat.isInbox ? Color.blue : Color.teal, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(chat.title).font(.headline).lineLimit(1)
                    Spacer()
                    if let last = chat.lastMessage {
                        Text(timeLabel(last.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(chat.lastMessage?.text ?? "No messages yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private func timeLabel(_ date: Date) -> String {
        Calendar.current.isDateInToday(date)
            ? date.formatted(.dateTime.hour().minute().locale(europeanLocale))
            : date.formatted(.dateTime.day().month(.abbreviated).locale(europeanLocale))
    }
}

#Preview {
    ChatListView()
        .modelContainer(try! JournalStore.makeContainer(inMemory: true))
}
