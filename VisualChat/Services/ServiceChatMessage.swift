//
//  ServiceChatMessage.swift
//  VisualChat
//
//  Created by Sravani Pagidela on 11/23/25.
//

import Foundation

struct ServiceChatMessage: Codable {
    let role: String
    let content: String?
    let toolCalls: [ToolCall]?
    let toolCallId: String?
    
    enum CodingKeys: String, CodingKey {
        case role, content
        case toolCalls = "tool_calls"
        case toolCallId = "tool_call_id"
    }
    
    // Convenience initializers
    init(role: String, content: String) {
        self.role = role
        self.content = content
        self.toolCalls = nil
        self.toolCallId = nil
    }
    
    init(role: String, content: String?, toolCalls: [ToolCall]?) {
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.toolCallId = nil
    }
    
    init(role: String, content: String, toolCallId: String) {
        self.role = role
        self.content = content
        self.toolCalls = nil
        self.toolCallId = toolCallId
    }
    
    // Helper properties
    var hasToolCalls: Bool {
        toolCalls != nil && !toolCalls!.isEmpty
    }
    
    var hasContent: Bool {
        content != nil && !content!.isEmpty
    }
    
    var isToolResponse: Bool {
        toolCallId != nil
    }
}
