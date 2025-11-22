//
//  ChatView.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/22/25.
//

import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var context

    @State var thread: ChatThread
    @State private var draftText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(sortedMessages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: sortedMessages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
            }

            Divider()

            HStack {
                TextField("Message...", text: $draftText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle(thread.title)
#if os(iOS)
// iOS-specific tweaks
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var sortedMessages: [ChatMessage] {
        thread.messages.sorted(by: { $0.createdAt < $1.createdAt })
    }

    private func sendMessage() {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = ChatMessage(
            text: text,
            isFromUser: true,
            createdAt: Date(),
            thread: thread
        )
        context.insert(userMessage)

        draftText = ""

        // Fake “bot” reply for now so you can see the flow:
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let reply = ChatMessage(
                text: "Echo: \(text)",
                isFromUser: false,
                createdAt: Date(),
                thread: thread
            )
            context.insert(reply)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = sortedMessages.last?.id {
            DispatchQueue.main.async {
                withAnimation {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
    }
}
