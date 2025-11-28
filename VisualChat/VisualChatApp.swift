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
            MainTabView()
        }
        .modelContainer(for: [ChatThread.self, ChatMessage.self, PhotoLibrary.self, Photo.self])
    }
}
