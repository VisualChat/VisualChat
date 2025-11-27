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

    @Bindable var thread: ChatThread
    @State private var draftText: String = ""
    @State private var isProcessing: Bool = false
    
    private let service = ServiceOpenAIService()

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
                    if isProcessing {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
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
        isProcessing = true

        // Get response from Azure OpenAI
        Task {
            do {
                // Build conversation history
                let conversationMessages = sortedMessages.map { message in
                    ServiceChatMessage(
                        role: message.isFromUser ? "user" : "assistant",
                        content: message.text
                    )
                }
                
                let response = try await service.sendChatCompletion(messages: conversationMessages)
                // TODO handl tool calls if the response contains tool calls.
                let reply = ChatMessage(
                    text: response.textContent ?? "Bot: " + text,
                    isFromUser: false,
                    createdAt: Date(),
                    thread: thread
                )
                context.insert(reply)
                
            } catch {
                // Handle error by showing error message
                let errorReply = ChatMessage(
                    text: "Sorry, I encountered an error: \(error.localizedDescription)",
                    isFromUser: false,
                    createdAt: Date(),
                    thread: thread
                )
                context.insert(errorReply)
            }
            
            isProcessing = false
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
