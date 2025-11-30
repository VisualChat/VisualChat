//
//  TextEncoderMobileClipS2.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/28/25.
//

import CoreML
import Foundation

/// Text encoder for MobileCLIP S2 using CoreML mlpackage
class TextEncoderMobileClipS2 {
    private var model: mobileclip_s2_text?
    private lazy var tokenizer = CLIPTokenizer()
    
    enum TextEncoderError: Error {
        case modelNotFound
        case modelLoadFailed(Error)
        case tokenizationFailed
        case predictionFailed(Error)
        case invalidOutput
    }
    
    /// Initialize the text encoder
    init() {}
    
    /// Load the compiled model asynchronously on a background thread
    /// - Throws: TextEncoderError if model cannot be loaded
    func loadModel() async throws {
        if model != nil { return }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        print("[TextEncoder] Starting model load...")
        
        try await Task(priority: .userInitiated) {
            let config = MLModelConfiguration()
            config.computeUnits = .all // Use all available compute units (CPU, GPU, ANE)
            do {
                let loadedModel = try mobileclip_s2_text(configuration: config)
                self.model = loadedModel
            } catch {
                throw TextEncoderError.modelLoadFailed(error)
            }
        }.value
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("[TextEncoder] Model loaded in \(String(format: "%.3f", timeElapsed))s")
    }
    
    /// Encode a text string to its embedding vector
    /// - Parameter text: Text string to encode
    /// - Returns: Array of Float values representing the text embedding
    /// - Throws: TextEncoderError if encoding fails
    func encode(text: String) async throws -> [Float] {
        guard let model = model else {
            throw TextEncoderError.modelNotFound
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Run encoding on background thread with userInitiated priority
        let result = try await Task(priority: .userInitiated) {
            let tokenizeStart = CFAbsoluteTimeGetCurrent()
            
            // Tokenize the text query
            let inputIds = self.tokenizer.encode_full(text: text)
            
            // Convert [Int] to MLMultiArray
            guard let inputArray = try? MLMultiArray(shape: [1, 77], dataType: .int32) else {
                throw TextEncoderError.tokenizationFailed
            }
            
            for (index, element) in inputIds.enumerated() {
                inputArray[index] = NSNumber(value: element)
            }
            
            let tokenizeTime = CFAbsoluteTimeGetCurrent() - tokenizeStart
            
            do {
                let inferenceStart = CFAbsoluteTimeGetCurrent()
                
                // Use the generated model's input structure
                let input = mobileclip_s2_textInput(text: inputArray)
                let output = try model.prediction(input: input)
                
                let inferenceTime = CFAbsoluteTimeGetCurrent() - inferenceStart
                
                // Extract the embedding from output
                let embedding = output.final_emb_1
                let floatArray = self.multiArrayToFloatArray(embedding)
                
                print("[TextEncoder] Tokenization: \(String(format: "%.3f", tokenizeTime))s, Inference: \(String(format: "%.3f", inferenceTime))s")
                
                return floatArray
            } catch {
                throw TextEncoderError.predictionFailed(error)
            }
        }.value
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        print("[TextEncoder] Total encoding time: \(String(format: "%.3f", totalTime))s")
        
        return result
    }
    
    /// Compute text embeddings for multiple prompts
    /// - Parameter promptArr: Array of text prompts to encode
    /// - Returns: Array of MLMultiArray embeddings
    func computeTextEmbeddings(promptArr: [String]) async -> [MLMultiArray] {
        var textEmbeddings: [MLMultiArray] = []
        
        for singlePrompt in promptArr {
            print("")
            print("Prompt text: \(singlePrompt)")
            
            do {
                // Tokenize the text query
                let inputIds = tokenizer.encode_full(text: singlePrompt)
                
                // Convert [Int] to MultiArray
                let inputArray = try MLMultiArray(shape: [1, 77], dataType: .int32)
                for (index, element) in inputIds.enumerated() {
                    inputArray[index] = NSNumber(value: element)
                }
                
                // Run the text model on the text query
                guard let model = model else {
                    print("Model not loaded")
                    continue
                }
                
                let input = mobileclip_s2_textInput(text: inputArray)
                let output = try await model.prediction(input: input)
                
                // Extract the embedding from output
                let embedding = output.final_emb_1
                textEmbeddings.append(embedding)
            } catch {
                print("Error encoding text: \(error.localizedDescription)")
            }
        }
        
        return textEmbeddings
    }
    
    /// Encode multiple text strings in batch
    /// - Parameter texts: Array of text strings to encode
    /// - Returns: Array of embedding arrays
    /// - Throws: TextEncoderError if encoding fails
    func encodeBatch(texts: [String]) async throws -> [[Float]] {
        var results: [[Float]] = []
        for text in texts {
            let embedding = try await encode(text: text)
            results.append(embedding)
        }
        return results
    }
    
    // MARK: - Private Helper Methods
    
    /// Convert MLMultiArray to Float array
    private func multiArrayToFloatArray(_ multiArray: MLMultiArray) -> [Float] {
        let length = multiArray.count
        var floatArray: [Float] = []
        floatArray.reserveCapacity(length)
        
        for i in 0..<length {
            floatArray.append(Float(truncating: multiArray[i]))
        }
        
        return floatArray
    }
}
