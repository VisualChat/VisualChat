//
//  MLXInferenceManager.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//
import Foundation
internal import Combine
import MLX
import MLXNN
//
//class MLXInferenceManager: ObservableObject {
//    @Published var isLoading = false
//    @Published var isReady = false
//    @Published var errorMessage: String?
//    
//    private var textEncoder: TextEncoder?
//    private var imageEncoder: ImageEncoder?
//    
//    private let textModelPath: String
//    private let imageModelPath: String
//    
//    static let shared = MLXInferenceManager()
//
//    init() {
//        // Get model paths from bundle
//        if let textPath = Bundle.main.path(forResource: "text_encoder_weights", ofType: "safetensors", inDirectory: "Models") {
//            self.textModelPath = textPath
//        } else {
//            self.textModelPath = ""
//        }
//        
//        if let imagePath = Bundle.main.path(forResource: "image_encoder_weights", ofType: "safetensors", inDirectory: "Models") {
//            self.imageModelPath = imagePath
//        } else {
//            self.imageModelPath = ""
//        }
//    }
//    
//    // MARK: - Model Loading
//    
//    func loadTextEncoder() throws {
//        guard !textModelPath.isEmpty else {
//            throw NSError(domain: "MLXInference", code: -1, userInfo: [NSLocalizedDescriptionKey: "Text model path not found"])
//        }
//        
//        let encoder = TextEncoder()
//        
//        // Load weights from safetensors
//        let weights = try loadSafetensors(path: textModelPath)
//        encoder.update(parameters: ModuleParameters.unflattened(weights))
//        
//        self.textEncoder = encoder
//        print("✅ Text encoder loaded successfully")
//    }
//    
//    func loadImageEncoder() throws {
//        guard !imageModelPath.isEmpty else {
//            throw NSError(domain: "MLXInference", code: -1, userInfo: [NSLocalizedDescriptionKey: "Image model path not found"])
//        }
//        
//        let encoder = ImageEncoder()
//        
//        // Load weights from safetensors
//        let weights = try loadSafetensors(path: imageModelPath)
//        encoder.update(parameters: ModuleParameters.unflattened(weights))
//        
//        self.imageEncoder = encoder
//        print("✅ Image encoder loaded successfully")
//    }
//    
//    func loadModels() async throws {
//        isLoading = true
//        errorMessage = nil
//        
//        do {
//            try loadTextEncoder()
//            try loadImageEncoder()
//            isReady = true
//            isLoading = false
//        } catch {
//            errorMessage = error.localizedDescription
//            isLoading = false
//            isReady = false
//            throw error
//        }
//    }
//    
//    // MARK: - Inference
//    
//    func encodeText(_ text: String) throws -> MLXArray {
//        guard let encoder = textEncoder else {
//            throw NSError(domain: "MLXInference", code: -1, userInfo: [NSLocalizedDescriptionKey: "Text encoder not loaded"])
//        }
//        
//        // Tokenize text (simplified - you'll need a proper tokenizer)
//        let tokens = tokenize(text)
//        let tokenArray = MLXArray(tokens)
//        
//        // Encode
//        let embedding = encoder(tokenArray)
//        
//        // Normalize
//        let normalized = embedding / sqrt(sum(embedding * embedding, axes: [-1], keepDims: true))
//        
//        return normalized
//    }
//    
//    func encodeImage(_ image: MLXArray) throws -> MLXArray {
//        guard let encoder = imageEncoder else {
//            throw NSError(domain: "MLXInference", code: -1, userInfo: [NSLocalizedDescriptionKey: "Image encoder not loaded"])
//        }
//        
//        // Preprocess image (normalize, resize if needed)
//        let preprocessed = preprocessImage(image)
//        
//        // Encode
//        let embedding = encoder(preprocessed)
//        
//        // Normalize
//        let normalized = embedding / sqrt(sum(embedding * embedding, axes: [-1], keepDims: true))
//        
//        return normalized
//    }
//    
//    func computeSimilarity(textEmbedding: MLXArray, imageEmbedding: MLXArray) -> Float {
//        let similarity = sum(textEmbedding * imageEmbedding).item(Float.self)
//        return similarity
//    }
//    
//    // MARK: - Helper Functions
//    
//    private func loadSafetensors(path: String) throws -> [String: MLXArray] {
//        let url = URL(fileURLWithPath: path)
//        let data = try Data(contentsOf: url)
//        
//        // Parse safetensors format
//        // Header: 8 bytes for header size (little endian)
//        let headerSize = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt64.self) }
//        
//        let headerStart = 8
//        let headerEnd = headerStart + Int(headerSize)
//        let headerData = data[headerStart..<headerEnd]
//        
//        guard let headerJson = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any] else {
//            throw NSError(domain: "MLXInference", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse safetensors header"])
//        }
//        
//        var weights: [String: MLXArray] = [:]
//        let tensorData = data[headerEnd...]
//        
//        for (name, value) in headerJson {
//            guard name != "__metadata__",
//                  let tensorInfo = value as? [String: Any],
//                  let shape = tensorInfo["shape"] as? [Int],
//                  let dtype = tensorInfo["dtype"] as? String,
//                  let dataOffsets = tensorInfo["data_offsets"] as? [Int],
//                  dataOffsets.count == 2 else {
//                continue
//            }
//            
//            let start = dataOffsets[0]
//            let end = dataOffsets[1]
//            let tensorBytes = tensorData[start..<end]
//            
//            // Convert to MLXArray based on dtype
//            let array = try createMLXArray(from: tensorBytes, shape: shape, dtype: dtype)
//            weights[name] = array
//        }
//        
//        return weights
//    }
//    
//    private func createMLXArray(from data: Data, shape: [Int], dtype: String) throws -> MLXArray {
//        // Convert data to MLXArray based on dtype
//        switch dtype {
//        case "F32":
//            let floats = data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
//            return MLXArray(floats, shape)
//        case "F16":
//            // Handle float16 conversion if needed
//            let floats = data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
//            return MLXArray(floats, shape)
//        default:
//            throw NSError(domain: "MLXInference", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported dtype: \(dtype)"])
//        }
//    }
//    
//    private func tokenize(_ text: String) -> [Int] {
//        // Simplified tokenization - replace with proper CLIP tokenizer
//        // For now, just pad to context length
//        var tokens = [Int](repeating: 0, count: 77)
//        tokens[0] = 49406 // Start token
//        
//        // Convert characters to tokens (simplified)
//        let chars = Array(text.lowercased())
//        for (i, char) in chars.prefix(75).enumerated() {
//            tokens[i + 1] = Int(char.asciiValue ?? 0) % 49407
//        }
//        
//        tokens[min(chars.count + 1, 76)] = 49407 // End token
//        
//        return tokens
//    }
//    
//    private func preprocessImage(_ image: MLXArray) -> MLXArray {
//        // Normalize image to [-1, 1] or [0, 1] depending on model
//        // Resize to expected input size
//        // Add batch dimension if needed
//        
//        var processed = image
//        
//        // Ensure NCHW format
//        if processed.ndim == 3 {
//            processed = expandedDimensions(processed, axis: 0)
//        }
//        
//        // Normalize
//        processed = (processed / 255.0 - 0.5) / 0.5
//        
//        return processed
//    }
//}
//
