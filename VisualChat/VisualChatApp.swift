//
//  VisualChatApp.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/15/25.
//

import SwiftUI
import SwiftData

@main
struct VisualChatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ChatThread.self, ChatMessage.self])
    }
}
