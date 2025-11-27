//
//  ServiceChatResponse.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/23/25.
//

import Foundation

struct ServiceChatResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: ServiceChatMessage
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
        
        // Helper properties
        var isToolCall: Bool {
            finishReason == "tool_calls" && message.hasToolCalls
        }
        
        var isTextResponse: Bool {
            finishReason != "tool_calls" && message.hasContent
        }
        
        var textContent: String? {
            message.content
        }
        
        var toolCalls: [ToolCall]? {
            message.toolCalls
        }
    }
    
    // Convenience properties for first choice
    var firstChoice: Choice? {
        choices.first
    }
    
    var isToolCallResponse: Bool {
        firstChoice?.isToolCall ?? false
    }
    
    var isTextResponse: Bool {
        firstChoice?.isTextResponse ?? false
    }
    
    var textContent: String? {
        firstChoice?.textContent
    }
    
    var toolCalls: [ToolCall]? {
        firstChoice?.toolCalls
    }
}
