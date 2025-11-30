//
//  HNSWIndexManager.swift
//  VisualChat
//
//  Created on 11/30/25.
//

import Foundation
internal import hnswlib_swift

/// Manager for HNSW (Hierarchical Navigable Small World) vector index
/// Uses cosine similarity for nearest neighbor search
actor HNSWIndexManager {
    
    // MARK: - Properties
    
    /// The HNSW index instance
    private var index: HNSWIndex?
    
    /// Dimension of the embedding vectors (MobileCLIP S2 outputs 512-dimensional embeddings)
    private let embeddingDimension: Int
    
    /// Mapping from HNSW label to Photo UUID
    private var labelToPhotoId: [UInt64: UUID] = [:]
    
    /// Mapping from Photo UUID to HNSW label
    private var photoIdToLabel: [UUID: UInt64] = [:]
    
    /// Next available label for adding items
    private var nextLabel: UInt64 = 0
    
    /// Path where index is persisted
    private let indexPath: URL
    
    /// Path where label mappings are persisted
    private let mappingsPath: URL
    
    // MARK: - Errors
    
    enum HNSWIndexError: LocalizedError {
        case indexNotInitialized
        case initializationFailed(String)
        case addItemFailed(String)
        case searchFailed(String)
        case saveFailed(String)
        case loadFailed(String)
        case invalidEmbeddingDimension(expected: Int, got: Int)
        
        var errorDescription: String? {
            switch self {
            case .indexNotInitialized:
                return "HNSW index is not initialized"
            case .initializationFailed(let message):
                return "Failed to initialize HNSW index: \(message)"
            case .addItemFailed(let message):
                return "Failed to add item to HNSW index: \(message)"
            case .searchFailed(let message):
                return "Failed to search HNSW index: \(message)"
            case .saveFailed(let message):
                return "Failed to save HNSW index: \(message)"
            case .loadFailed(let message):
                return "Failed to load HNSW index: \(message)"
            case .invalidEmbeddingDimension(let expected, let got):
                return "Invalid embedding dimension: expected \(expected), got \(got)"
            }
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize the HNSW index manager
    /// - Parameters:
    ///   - libraryId: Unique identifier for the photo library
    ///   - embeddingDimension: Dimension of the embedding vectors (default: 512 for MobileCLIP S2)
    init(libraryId: UUID, embeddingDimension: Int = 512) {
        self.embeddingDimension = embeddingDimension
        
        // Create directory for storing index files
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let indexDirectory = documentsPath.appendingPathComponent("HNSWIndices", isDirectory: true)
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: indexDirectory, withIntermediateDirectories: true)
        
        self.indexPath = indexDirectory.appendingPathComponent("\(libraryId.uuidString).hnsw")
        self.mappingsPath = indexDirectory.appendingPathComponent("\(libraryId.uuidString).mappings")
    }
    
    // MARK: - Index Management
    
    /// Initialize a new HNSW index
    /// - Parameters:
    ///   - maxElements: Maximum number of elements the index can hold
    ///   - m: Number of bidirectional links per node (higher = more accurate but slower, default: 16)
    ///   - efConstruction: Size of dynamic list during construction (higher = more accurate but slower build, default: 200)
    func initializeIndex(maxElements: Int, m: Int = 16, efConstruction: Int = 200) throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        print("[HNSWIndex] Initializing new index with maxElements: \(maxElements), m: \(m), efConstruction: \(efConstruction)")
        
        do {
            // Create index with cosine similarity space type
            index = try HNSWIndex(spaceType: .cosine, dim: embeddingDimension)
            
            try index?.initIndex(
                maxElements: maxElements,
                m: m,
                efConstruction: efConstruction,
                randomSeed: 100,
                allowReplaceDeleted: true
            )
            
            // Set ef parameter for search (controls accuracy vs speed tradeoff)
            index?.setEf(ef: 100)
            
            // Reset mappings
            labelToPhotoId = [:]
            photoIdToLabel = [:]
            nextLabel = 0
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("[HNSWIndex] Index initialized in \(String(format: "%.3f", timeElapsed))s")
        } catch {
            throw HNSWIndexError.initializationFailed(error.localizedDescription)
        }
    }
    
    /// Load an existing index from disk
    func loadIndex() throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        print("[HNSWIndex] Loading index from \(indexPath.path)")
        
        guard FileManager.default.fileExists(atPath: indexPath.path) else {
            throw HNSWIndexError.loadFailed("Index file does not exist at \(indexPath.path)")
        }
        
        do {
            // Load the HNSW index
            index = try HNSWIndex.loadIndex(
                spaceType: .cosine,
                dim: embeddingDimension,
                path: indexPath.path
            )
            
            // Set ef parameter for search
            index?.setEf(ef: 100)
            
            // Load the mappings
            try loadMappings()
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("[HNSWIndex] Index loaded in \(String(format: "%.3f", timeElapsed))s with \(currentCount) elements")
        } catch let error as HNSWIndexError {
            throw error
        } catch {
            throw HNSWIndexError.loadFailed(error.localizedDescription)
        }
    }
    
    /// Save the current index to disk
    func saveIndex() throws {
        guard let index = index else {
            throw HNSWIndexError.indexNotInitialized
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        print("[HNSWIndex] Saving index to \(indexPath.path)")
        
        do {
            try index.saveIndex(path: indexPath.path)
            try saveMappings()
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("[HNSWIndex] Index saved in \(String(format: "%.3f", timeElapsed))s")
        } catch {
            throw HNSWIndexError.saveFailed(error.localizedDescription)
        }
    }
    
    /// Check if an index file exists on disk
    var indexExists: Bool {
        FileManager.default.fileExists(atPath: indexPath.path)
    }
    
    /// Get the current number of elements in the index
    var currentCount: Int {
        index?.currentCount ?? 0
    }
    
    // MARK: - Adding Items
    
    /// Add a single photo embedding to the index
    /// - Parameters:
    ///   - embedding: The embedding vector
    ///   - photoId: The UUID of the photo
    func addItem(embedding: [Float], photoId: UUID) throws {
        guard let index = index else {
            throw HNSWIndexError.indexNotInitialized
        }
        
        guard embedding.count == embeddingDimension else {
            throw HNSWIndexError.invalidEmbeddingDimension(expected: embeddingDimension, got: embedding.count)
        }
        
        // Check if photo already exists and update mapping if needed
        if let existingLabel = photoIdToLabel[photoId] {
            // Photo already indexed, skip or update
            index.markDeleted(label: existingLabel)
            labelToPhotoId.removeValue(forKey: existingLabel)
        }
        
        let label = nextLabel
        nextLabel += 1
        
        do {
            try index.addItems(data: [embedding], ids: [label])
            
            // Update mappings
            labelToPhotoId[label] = photoId
            photoIdToLabel[photoId] = label
        } catch {
            throw HNSWIndexError.addItemFailed(error.localizedDescription)
        }
    }
    
    /// Add multiple photo embeddings to the index in batch
    /// - Parameters:
    ///   - embeddings: Array of embedding vectors
    ///   - photoIds: Array of photo UUIDs (must match embeddings array length)
    func addItems(embeddings: [[Float]], photoIds: [UUID]) throws {
        guard let index = index else {
            throw HNSWIndexError.indexNotInitialized
        }
        
        guard embeddings.count == photoIds.count else {
            throw HNSWIndexError.addItemFailed("Embeddings and photoIds arrays must have the same length")
        }
        
        for embedding in embeddings {
            guard embedding.count == embeddingDimension else {
                throw HNSWIndexError.invalidEmbeddingDimension(expected: embeddingDimension, got: embedding.count)
            }
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Generate labels for new items
        var labels: [UInt64] = []
        for _ in embeddings {
            labels.append(nextLabel)
            nextLabel += 1
        }
        
        do {
            try index.addItems(data: embeddings, ids: labels)
            
            // Update mappings
            for (i, label) in labels.enumerated() {
                let photoId = photoIds[i]
                
                // Remove old mapping if photo was already indexed
                if let oldLabel = photoIdToLabel[photoId] {
                    labelToPhotoId.removeValue(forKey: oldLabel)
                }
                
                labelToPhotoId[label] = photoId
                photoIdToLabel[photoId] = label
            }
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("[HNSWIndex] Added \(embeddings.count) items in \(String(format: "%.3f", timeElapsed))s")
        } catch {
            throw HNSWIndexError.addItemFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Search
    
    /// Search result structure
    struct SearchResult {
        /// The photo UUID
        let photoId: UUID
        /// Cosine similarity score (0-1, higher is more similar)
        let similarity: Float
    }
    
    /// Search for nearest neighbors using a query embedding
    /// - Parameters:
    ///   - queryEmbedding: The query embedding vector
    ///   - k: Number of nearest neighbors to return
    ///   - threshold: Minimum similarity threshold (0-1, default: 0.0)
    /// - Returns: Array of search results sorted by similarity (highest first)
    func search(queryEmbedding: [Float], k: Int, threshold: Float = 0.0) throws -> [SearchResult] {
        guard let index = index else {
            throw HNSWIndexError.indexNotInitialized
        }
        
        guard queryEmbedding.count == embeddingDimension else {
            throw HNSWIndexError.invalidEmbeddingDimension(expected: embeddingDimension, got: queryEmbedding.count)
        }
        
        guard currentCount > 0 else {
            return []
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Adjust k to not exceed current count
        let effectiveK = min(k, currentCount)
        
        do {
            let results = try index.searchKnn(query: [queryEmbedding], k: effectiveK)
            
            var searchResults: [SearchResult] = []
            
            for i in 0..<effectiveK {
                let label = results.labels[0][i]
                let distance = results.distances[0][i]
                
                // Convert distance to similarity
                // For cosine space in hnswlib, distance = 1 - cosine_similarity
                // So similarity = 1 - distance
                let similarity = 1.0 - distance
                
                if let photoId = labelToPhotoId[label], similarity >= threshold {
                    searchResults.append(SearchResult(photoId: photoId, similarity: similarity))
                }
            }
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("[HNSWIndex] Search completed in \(String(format: "%.3f", timeElapsed))s, found \(searchResults.count) results")
            
            return searchResults
        } catch {
            throw HNSWIndexError.searchFailed(error.localizedDescription)
        }
    }
    
    /// Search for nearest neighbors using multiple query embeddings
    /// - Parameters:
    ///   - queryEmbeddings: Array of query embedding vectors
    ///   - k: Number of nearest neighbors to return per query
    ///   - threshold: Minimum similarity threshold (0-1, default: 0.0)
    /// - Returns: Array of search result arrays, one per query
    func searchBatch(queryEmbeddings: [[Float]], k: Int, threshold: Float = 0.0) throws -> [[SearchResult]] {
        guard let index = index else {
            throw HNSWIndexError.indexNotInitialized
        }
        
        for embedding in queryEmbeddings {
            guard embedding.count == embeddingDimension else {
                throw HNSWIndexError.invalidEmbeddingDimension(expected: embeddingDimension, got: embedding.count)
            }
        }
        
        guard currentCount > 0 else {
            return queryEmbeddings.map { _ in [] }
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let effectiveK = min(k, currentCount)
        
        do {
            let results = try index.searchKnn(query: queryEmbeddings, k: effectiveK)
            
            var allSearchResults: [[SearchResult]] = []
            
            for queryIdx in 0..<queryEmbeddings.count {
                var searchResults: [SearchResult] = []
                
                for i in 0..<effectiveK {
                    let label = results.labels[queryIdx][i]
                    let distance = results.distances[queryIdx][i]
                    let similarity = 1.0 - distance
                    
                    if let photoId = labelToPhotoId[label], similarity >= threshold {
                        searchResults.append(SearchResult(photoId: photoId, similarity: similarity))
                    }
                }
                
                allSearchResults.append(searchResults)
            }
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("[HNSWIndex] Batch search completed in \(String(format: "%.3f", timeElapsed))s for \(queryEmbeddings.count) queries")
            
            return allSearchResults
        } catch {
            throw HNSWIndexError.searchFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Deletion
    
    /// Remove a photo from the index
    /// - Parameter photoId: The UUID of the photo to remove
    func removeItem(photoId: UUID) {
        guard let label = photoIdToLabel[photoId] else {
            return
        }
        
        index?.markDeleted(label: label)
        labelToPhotoId.removeValue(forKey: label)
        photoIdToLabel.removeValue(forKey: photoId)
    }
    
    /// Clear all items from the index
    func clearIndex() throws {
        let maxElements = index?.maxElements ?? 10000
        try initializeIndex(maxElements: maxElements)
    }
    
    /// Resize the index to accommodate more elements
    /// - Parameter newMaxElements: New maximum number of elements
    func resizeIndex(newMaxElements: Int) throws {
        guard let index = index else {
            throw HNSWIndexError.indexNotInitialized
        }
        
        do {
            try index.resizeIndex(newSize: newMaxElements)
            print("[HNSWIndex] Index resized to \(newMaxElements) max elements")
        } catch {
            throw HNSWIndexError.initializationFailed("Failed to resize index: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Save label mappings to disk
    private func saveMappings() throws {
        // Convert UInt64 keys to String and UUID values to String
        var labelToPhotoIdStr: [String: String] = [:]
        for (label, uuid) in labelToPhotoId {
            labelToPhotoIdStr[String(label)] = uuid.uuidString
        }
        
        // Convert UUID keys to String and UInt64 values to String
        var photoIdToLabelStr: [String: String] = [:]
        for (uuid, label) in photoIdToLabel {
            photoIdToLabelStr[uuid.uuidString] = String(label)
        }
        
        let mappingsData = MappingsData(
            labelToPhotoId: labelToPhotoIdStr,
            photoIdToLabel: photoIdToLabelStr,
            nextLabel: nextLabel
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(mappingsData)
        try data.write(to: mappingsPath)
    }
    
    /// Load label mappings from disk
    private func loadMappings() throws {
        guard FileManager.default.fileExists(atPath: mappingsPath.path) else {
            throw HNSWIndexError.loadFailed("Mappings file does not exist at \(mappingsPath.path)")
        }
        
        let data = try Data(contentsOf: mappingsPath)
        let decoder = JSONDecoder()
        let mappingsData = try decoder.decode(MappingsData.self, from: data)
        
        // Reconstruct mappings
        labelToPhotoId = [:]
        photoIdToLabel = [:]
        
        for (labelStr, uuidStr) in mappingsData.labelToPhotoId {
            if let label = UInt64(labelStr), let uuid = UUID(uuidString: uuidStr) {
                labelToPhotoId[label] = uuid
            }
        }
        
        for (uuidStr, labelStr) in mappingsData.photoIdToLabel {
            if let uuid = UUID(uuidString: uuidStr), let label = UInt64(labelStr) {
                photoIdToLabel[uuid] = label
            }
        }
        
        nextLabel = mappingsData.nextLabel
    }
}

// MARK: - Helper Types

/// Structure for persisting label mappings
private struct MappingsData: Codable {
    let labelToPhotoId: [String: String]  // UInt64 -> UUID as strings
    let photoIdToLabel: [String: String]  // UUID -> UInt64 as strings
    let nextLabel: UInt64
}
