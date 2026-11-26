import SwiftData
import SwiftUI

/// Screen 2: one chat. Messages grow upward from the input bar, like Telegram.
struct ChatView: View {
    let chat: Chat
    @Environment(\.modelContext) private var context
    @Query private var messages: [Message]
    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    init(chat: Chat) {
        self.chat = chat
        let chatID = chat.id
        _messages = Query(filter: #Predicate<Message> { $0.chat?.id == chatID }, sort: \Message.date)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                        if startsNewDay(at: index) {
                            DayHeader(date: message.date)
                        }
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .accessibilityIdentifier("chatList")
            .overlay {
                if messages.isEmpty { EmptyChat() }
            }
            .onChange(of: messages.last?.id) { _, lastID in
                guard let lastID else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
        .background(ChatBackground())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            InputBar(text: $draft, focused: $inputFocused, onSend: send)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(chat.title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var subtitle: String {
        messages.count == 1 ? "1 message" : "\(messages.count) messages"
    }

    private func startsNewDay(at index: Int) -> Bool {
        guard index > 0 else { return true }
        return !Calendar.current.isDate(
            messages[index].date,
            inSameDayAs: messages[index - 1].date
        )
    }

    private func send() {
        if JournalStore(context: context).send(draft, to: chat) != nil {
            draft = ""
        }
    }
}

// MARK: - Pieces

let europeanLocale = Locale(identifier: "en_GB")

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            Spacer(minLength: 56)
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(message.text)
                    .foregroundStyle(.black)
                    .textSelection(.enabled)
                Text(message.date.formatted(.dateTime.hour().minute().locale(europeanLocale)))
                    .font(.caption2)
                    .foregroundStyle(Color(red: 0.31, green: 0.62, blue: 0.27))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 17, bottomLeadingRadius: 17,
                    bottomTrailingRadius: 5, topTrailingRadius: 17
                )
                .fill(Color(red: 0.88, green: 0.99, blue: 0.80))
            )
        }
    }
}

struct DayHeader: View {
    let date: Date

    var body: some View {
        Text(label)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.black.opacity(0.22), in: Capsule())
            .padding(.vertical, 6)
    }

    private var label: String {
        Calendar.current.isDateInToday(date)
            ? "Today"
            : date.formatted(.dateTime.day().month(.wide).year().locale(europeanLocale))
    }
}

struct EmptyChat: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("No messages here yet…").font(.headline)
            Text("Write something below.").font(.subheadline)
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 18))
    }
}

struct ChatBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.62, green: 0.82, blue: 0.70),
                Color(red: 0.55, green: 0.66, blue: 0.88),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct InputBar: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    let onSend: () -> Void

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var remaining: Int {
        JournalStore.characterLimit - text.count
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message", text: $text, axis: .vertical)
                .lineLimit(1...6)
                .focused(focused)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(.separator), lineWidth: 0.5))
                .accessibilityIdentifier("messageInput")
                .onChange(of: text) { _, newValue in
                    if newValue.count > JournalStore.characterLimit {
                        text = String(newValue.prefix(JournalStore.characterLimit))
                    }
                }

            VStack(spacing: 2) {
                if remaining <= 100 {
                    Text("\(remaining)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(remaining == 0 ? .red : .secondary)
                        .accessibilityIdentifier("charactersLeft")
                }
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                }
                .disabled(!canSend)
                .accessibilityLabel("Send")
                .accessibilityIdentifier("sendButton")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.bar)
    }
}

#Preview {
    let container = try! JournalStore.makeContainer(inMemory: true)
    let chat = JournalStore(context: container.mainContext).ensureInbox()
    return NavigationStack { ChatView(chat: chat) }
        .modelContainer(container)
}
