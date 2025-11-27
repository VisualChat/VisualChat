//
//  ToolModels.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/23/25.
//

import Foundation

struct ToolCall: Codable {
    let id: String
    let type: String
    let function: FunctionCall
    
    struct FunctionCall: Codable {
        let name: String
        let arguments: String
    }
}

struct ToolDefinition: Codable {
    let type: String
    let function: FunctionDefinition
    
    struct FunctionDefinition: Codable {
        let name: String
        let description: String
        let parameters: Parameters
        
        struct Parameters: Codable {
            let type: String
            let properties: [String: Property]
            let required: [String]?
            
            struct Property: Codable {
                let type: String
                let description: String
                let enumValues: [String]?
                
                enum CodingKeys: String, CodingKey {
                    case type, description
                    case enumValues = "enum"
                }
            }
        }
    }
}
