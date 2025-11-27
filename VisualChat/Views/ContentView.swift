//
//  ContentView.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/15/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ChatThread.createdAt, order: .reverse)
    private var threads: [ChatThread]

    @State private var newThreadTitle: String = ""
    @State private var selectedThread: ChatThread?

    var body: some View {
        NavigationSplitView {
            // Sidebar with chat threads
            VStack {
                List(selection: $selectedThread) {
                    ForEach(threads) { thread in
                        Button {
                            selectedThread = thread
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(thread.title)
                                        .font(.headline)
                                    if let lastMessage = thread.messages.sorted(by: { $0.createdAt > $1.createdAt }).first {
                                        Text(lastMessage.text)
                                            .font(.subheadline)
                                            .lineLimit(1)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .tag(thread)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteThread(thread)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteThread(thread)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .navigationTitle("Chats")
                
                HStack {
                    TextField("New chat title", text: $newThreadTitle)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        addThread()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newThreadTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
        } detail: {
            // Detail view
            if let thread = selectedThread {
                ChatView(thread: thread)
            } else {
                ContentUnavailableView(
                    "Select a Chat",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Choose a chat from the sidebar or create a new one")
                )
            }
        }
    }

    private func addThread() {
        let title = newThreadTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }

        let thread = ChatThread(title: title)
        context.insert(thread)

        // SwiftData auto-saves often; you can force if needed:
        // try? context.save()

        newThreadTitle = ""
    }

    private func deleteThread(_ thread: ChatThread) {
        if selectedThread?.id == thread.id {
            selectedThread = nil
        }
        context.delete(thread)
    }
}
