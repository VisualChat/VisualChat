//
//  ServiceOpenAIService.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/22/25.
//

import Foundation

@MainActor
class ServiceOpenAIService {
    // Remove trailing slash from endpoint
    private let endpoint = "https://ai-scgopireddy2338ai803056405339.openai.azure.com"
    private let modelName = "gpt-5.1"
    private let deployment = "gpt-5.1"
    private let apiVersion = "2025-01-01-preview"
    
    // Replace with your actual API key
    private let subscriptionKey = "<<Azure OpenAI Subscription Key>>"
    
    func sendChatCompletion(messages: [ServiceChatMessage], tools: [ToolDefinition]? = nil, toolChoice: String? = nil) async throws -> ServiceChatResponse {
        // Build the full URL - Azure OpenAI format
        let urlString = "\(endpoint)/openai/deployments/\(deployment)/chat/completions?api-version=\(apiVersion)"
        
        print("DEBUG: Attempting to connect to: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("DEBUG: Failed to create URL from string: \(urlString)")
            throw URLError(.badURL)
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(subscriptionKey, forHTTPHeaderField: "api-key")
        request.timeoutInterval = 30
        
        // Create the request body
        let requestBody = ServiceChatRequest(
            messages: messages,
            maxCompletionTokens: 16384,
            model: deployment,
            tools: tools,
            toolChoice: toolChoice
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // Make the request with better error handling
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            print("DEBUG: Response status code: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to decode error message
                if let errorString = String(data: data, encoding: .utf8) {
                    print("DEBUG: Error response: \(errorString)")
                }
                throw URLError(.badServerResponse)
            }
            
            // Decode the response
            let chatResponse = try JSONDecoder().decode(ServiceChatResponse.self, from: data)
            
            return chatResponse
            
        } catch let error as NSError {
            print("DEBUG: Network error occurred")
            print("DEBUG: Error domain: \(error.domain)")
            print("DEBUG: Error code: \(error.code)")
            print("DEBUG: Error description: \(error.localizedDescription)")
            print("DEBUG: Error info: \(error.userInfo)")
            throw error
        }
    }
    
    // Convenience method for simple chat completion (backward compatibility)
    func getCompletion(systemPrompt: String = "You are a helpful assistant.", userMessage: String) async throws -> String {
        let messages = [
            ServiceChatMessage(role: "system", content: systemPrompt),
            ServiceChatMessage(role: "user", content: userMessage)
        ]
        
        let response = try await sendChatCompletion(messages: messages)
        
        guard let firstChoice = response.choices.first else {
            throw URLError(.cannotDecodeContentData)
        }
        
        return firstChoice.message.content ?? ""
    }
    
    // Convenience method for chat completion with tools
    func sendChatCompletionWithTools(messages: [ServiceChatMessage], tools: [ToolDefinition], toolChoice: String = "auto") async throws -> ServiceChatResponse {
        return try await sendChatCompletion(messages: messages, tools: tools, toolChoice: toolChoice)
    }
}
