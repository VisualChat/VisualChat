//
//  ServiceChatRequest.swift
//  VisualChat
//
//  Created by Sravani Pagidela on 11/23/25.
//

import Foundation

struct ServiceChatRequest: Codable {
    let messages: [ServiceChatMessage]
    let maxCompletionTokens: Int
    let model: String
    let tools: [ToolDefinition]?
    let toolChoice: String?
    
    enum CodingKeys: String, CodingKey {
        case messages
        case maxCompletionTokens = "max_completion_tokens"
        case model
        case tools
        case toolChoice = "tool_choice"
    }
    
    // Convenience initializer for backward compatibility
    init(messages: [ServiceChatMessage], maxCompletionTokens: Int, model: String, tools: [ToolDefinition]? = nil, toolChoice: String? = nil) {
        self.messages = messages
        self.maxCompletionTokens = maxCompletionTokens
        self.model = model
        self.tools = tools
        self.toolChoice = toolChoice
    }
}
