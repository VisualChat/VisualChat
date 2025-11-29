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

@Model
class PhotoLibrary {
    @Attribute(.unique) var id: UUID
    var path: String
    var name: String
    var createdAt: Date
    var lastIndexedAt: Date?
    var securityBookmark: Data?
    @Relationship(deleteRule: .cascade, inverse: \Photo.library)
    var photos: [Photo] = []

    init(
        id: UUID = UUID(),
        path: String,
        name: String,
        createdAt: Date = Date(),
        lastIndexedAt: Date? = nil,
        securityBookmark: Data? = nil
    ) {
        self.id = id
        self.path = path
        self.name = name
        self.createdAt = createdAt
        self.lastIndexedAt = lastIndexedAt
        self.securityBookmark = securityBookmark
    }
}

@Model
class Photo {
    @Attribute(.unique) var id: UUID
    var filePath: String
    var fileName: String
    var fileSize: Int64
    var createdAt: Date
    var modifiedAt: Date
    var embedding: [Float]? // Image embedding vector from MobileCLIP
    var library: PhotoLibrary?

    init(
        id: UUID = UUID(),
        filePath: String,
        fileName: String,
        fileSize: Int64,
        createdAt: Date = Date(),
        modifiedAt: Date,
        embedding: [Float]? = nil,
        library: PhotoLibrary? = nil
    ) {
        self.id = id
        self.filePath = filePath
        self.fileName = fileName
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.embedding = embedding
        self.library = library
    }
}
