//
//  Models.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/22/25.
//

import SwiftData
import Foundation

@Model
class ChatThread {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.thread)
    var messages: [ChatMessage] = []

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
    }
}

@Model
class ChatMessage {
    @Attribute(.unique) var id: UUID
    var text: String
    var isFromUser: Bool
    var createdAt: Date
    var thread: ChatThread?

    init(
        id: UUID = UUID(),
        text: String,
        isFromUser: Bool,
        createdAt: Date = Date(),
        thread: ChatThread? = nil
    ) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.createdAt = createdAt
        self.thread = thread
    }
}
