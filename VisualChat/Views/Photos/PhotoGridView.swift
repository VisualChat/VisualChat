//
//  PhotoGridView.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//

import SwiftUI
import SwiftData

struct PhotoGridView: View {
    let library: PhotoLibrary
    
    @Query private var allPhotos: [Photo]
    @State private var selectedPhoto: Photo?
    @State private var searchText = ""
    @State private var textEncoder = TextEncoderMobileClipS2()
    @State private var searchResults: [Photo] = []
    @State private var isSearching = false
    @State private var photoIndexingService = PhotoIndexingService()
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]
    
    init(library: PhotoLibrary) {
        self.library = library
        // Query photos for this library, sorted by modifiedAt descending
        let libraryID = library.id
        _allPhotos = Query(
            filter: #Predicate<Photo> { photo in
                photo.library?.id == libraryID
            },
            sort: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
    }
    
    var filteredPhotos: [Photo] {
        if searchText.isEmpty {
            return allPhotos
        } else {
            return searchResults
        }
    }
    
    var body: some View {
        VStack {
            if allPhotos.isEmpty {
                ContentUnavailableView(
                    "No Photos",
                    systemImage: "photo.on.rectangle",
                    description: Text("This library hasn't been indexed yet or contains no photos")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredPhotos) { photo in
                            PhotoThumbnailView(photo: photo)
                                .onTapGesture {
                                    selectedPhoto = photo
                                }
                        }
                    }
                    .padding()
                }
                .searchable(text: $searchText, prompt: "Search photos")
                .task(id: searchText) {
                    await performSearch()
                }
            }
        }
        .navigationTitle(library.name)
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
        }
        .task {
            // Load text encoder and HNSW index
            try? await textEncoder.loadModel()
            try? await photoIndexingService.loadHNSWIndex(for: library)
        }
    }
    
    /// Perform search using HNSW index with fallback to brute force
    private func performSearch() async {
        if searchText.isEmpty {
            searchResults = []
            return
        }
        
        isSearching = true
        let startTime = Date()
        
        do {
            let embedding = try await textEncoder.encode(text: searchText)
            
            // Try HNSW search first (much faster for large collections)
            do {
                let hnswResults = try await photoIndexingService.searchPhotos(
                    queryEmbedding: embedding,
                    library: library,
                    k: 50,  // Get top 50 results
                    threshold: 0.0  // Minimum similarity threshold
                )
                
                // Map results back to Photo objects by fetching from model context
                let photoIds = Set(hnswResults.map { $0.photoId })
                let matchedPhotos = allPhotos.filter { photoIds.contains($0.id) }
                
                // Sort by similarity score
                let photoIdToSimilarity = Dictionary(uniqueKeysWithValues: hnswResults.map { ($0.photoId, $0.similarity) })
                searchResults = matchedPhotos.sorted { photo1, photo2 in
                    let sim1 = photoIdToSimilarity[photo1.id] ?? 0
                    let sim2 = photoIdToSimilarity[photo2.id] ?? 0
                    return sim1 > sim2
                }
                
                print("[PhotoSearch] HNSW search took \(Date().timeIntervalSince(startTime)) seconds, found \(searchResults.count) results")
            } catch {
                // Fallback to brute force search if HNSW fails
                print("[PhotoSearch] HNSW search failed, falling back to brute force: \(error)")
                await performBruteForceSearch(embedding: embedding)
            }
        } catch {
            print("[PhotoSearch] Search failed: \(error)")
        }
        
        isSearching = false
    }
    
    /// Fallback brute force search using cosine similarity
    private func performBruteForceSearch(embedding: [Float]) async {
        let startTime = Date()
        
        let sortedPhotos = allPhotos.compactMap { photo -> (Photo, Float)? in
            guard let photoEmbedding = photo.embedding else { return nil }
            let similarity = Utils.cosineSimilarity(embedding, photoEmbedding)
            return similarity >= 0.5 ? (photo, similarity) : nil
        }
        .sorted { $0.1 > $1.1 }
        .map { $0.0 }
        
        searchResults = sortedPhotos
        print("[PhotoSearch] Brute force search took \(Date().timeIntervalSince(startTime)) seconds, found \(searchResults.count) results")
    }
}
