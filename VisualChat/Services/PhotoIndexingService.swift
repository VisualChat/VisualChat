//
//  PhotoIndexingService.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//

import Foundation
import SwiftData
internal import Combine
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

class PhotoIndexingService: ObservableObject {
    @MainActor @Published var isIndexing = false
    @MainActor @Published var progress: Double = 0
    @MainActor @Published var statusMessage = ""
    
    private let supportedExtensions = ["jpg", "jpeg", "png", "heic", "heif", "gif", "tiff", "tif", "bmp", "webp"]
    private var imageEncoder: ImageEncoderMobileClipS2?
    
    func indexPhotos(at path: String, library: PhotoLibrary, context: ModelContext) async throws {
        let totalStartTime = CFAbsoluteTimeGetCurrent()
        print("[PhotoIndexing] Starting indexing for path: \(path)")
        
        await MainActor.run {
            isIndexing = true
            progress = 0
            statusMessage = "Starting indexing..."
        }
        
        // Initialize image encoder if not already loaded
        if imageEncoder == nil {
            let modelLoadStart = CFAbsoluteTimeGetCurrent()
            imageEncoder = ImageEncoderMobileClipS2()
            await MainActor.run { statusMessage = "Loading image encoder model..." }
            do {
                try await imageEncoder?.loadModel()
                let modelLoadTime = CFAbsoluteTimeGetCurrent() - modelLoadStart
                print("[PhotoIndexing] Image encoder loaded in \(String(format: "%.3f", modelLoadTime))s")
            } catch {
                print("[PhotoIndexing] Warning: Failed to load image encoder: \(error). Continuing without embeddings.")
                imageEncoder = nil
            }
        }
        
        defer {
            Task { @MainActor in
                isIndexing = false
                statusMessage = ""
            }
        }
        
        let url = URL(fileURLWithPath: path)
        
        // Request security-scoped access if we have a bookmark
        var scopedURL: URL?
        #if os(macOS)
        if let bookmarkData = library.securityBookmark {
            var isStale = false
            do {
                scopedURL = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                _ = scopedURL?.startAccessingSecurityScopedResource()
            } catch {
                print("Failed to resolve bookmark during indexing: \(error)")
            }
        }
        #endif
        
        defer {
            #if os(macOS)
            scopedURL?.stopAccessingSecurityScopedResource()
            #endif
        }
        
        // Verify path exists on background thread
        let pathExists = await Task(priority: .userInitiated) {
            FileManager.default.fileExists(atPath: path)
        }.value
        
        guard pathExists else {
            throw PhotoIndexingError.pathNotFound
        }
        
        // Clear existing photos for this library
        await MainActor.run {
            for photo in library.photos {
                context.delete(photo)
            }
        }
        
        // Get all photo files on background thread
        let scanStartTime = CFAbsoluteTimeGetCurrent()
        await MainActor.run { statusMessage = "Scanning directory..." }
        let photoFiles = await Task(priority: .userInitiated) { [supportedExtensions] in
            var files: [URL] = []
            if let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) {
                for case let fileURL as URL in enumerator {
                    if supportedExtensions.contains(fileURL.pathExtension.lowercased()) {
                        files.append(fileURL)
                    }
                }
            }
            return files
        }.value
        
        let scanTime = CFAbsoluteTimeGetCurrent() - scanStartTime
        print("[PhotoIndexing] Scanned directory in \(String(format: "%.3f", scanTime))s, found \(photoFiles.count) photos")
        await MainActor.run { statusMessage = "Found \(photoFiles.count) photos" }
        
        // Index photos in batches to allow UI updates
        let encodingStartTime = CFAbsoluteTimeGetCurrent()
        let batchSize = 10
        for batchStart in stride(from: 0, to: photoFiles.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, photoFiles.count)
            let batch = Array(photoFiles[batchStart..<batchEnd])
            
            // Process batch on background thread with userInitiated priority
            let photoDataWithEmbeddings = await Task(priority: .userInitiated) { [imageEncoder] () async -> [(path: String, name: String, size: Int64, date: Date, embedding: [Float]?)] in
                await withTaskGroup(of: (path: String, name: String, size: Int64, date: Date, embedding: [Float]?)?.self) { group in
                    for fileURL in batch {
                        group.addTask(priority: .userInitiated) {
                            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]) else {
                                return nil
                            }

                            var embedding: [Float]? = nil
                            if let encoder = imageEncoder {
                                #if os(macOS)
                                if let image = NSImage(contentsOf: fileURL) {
                                    // Encode on background thread
                                    embedding = try? await encoder.encode(image: image)
                                }
                                #elseif os(iOS)
                                if let image = UIImage(contentsOfFile: fileURL.path) {
                                    // Encode on background thread
                                    embedding = try? await encoder.encode(image: image)
                                }
                                #endif
                            }

                            return (
                                path: fileURL.path,
                                name: fileURL.lastPathComponent,
                                size: Int64(resourceValues.fileSize ?? 0),
                                date: resourceValues.contentModificationDate ?? Date(),
                                embedding: embedding
                            )
                        }
                    }

                    var results: [(path: String, name: String, size: Int64, date: Date, embedding: [Float]?)] = []
                    for await item in group {
                        if let item { results.append(item) }
                    }
                    return results
                }
            }.value
            
            // Insert on main actor with context operations
            await MainActor.run {
                for data in photoDataWithEmbeddings {
                    let photo = Photo(
                        filePath: data.path,
                        fileName: data.name,
                        fileSize: data.size,
                        modifiedAt: data.date,
                        embedding: data.embedding,
                        library: library
                    )
                    context.insert(photo)
                }
                
                progress = Double(batchEnd) / Double(photoFiles.count)
                statusMessage = "Indexed \(batchEnd) of \(photoFiles.count) (with embeddings)"
            }
        }
        
        let encodingTime = CFAbsoluteTimeGetCurrent() - encodingStartTime
        let totalTime = CFAbsoluteTimeGetCurrent() - totalStartTime
        print("[PhotoIndexing] Encoding phase: \(String(format: "%.3f", encodingTime))s")
        print("[PhotoIndexing] Total indexing time: \(String(format: "%.3f", totalTime))s for \(photoFiles.count) photos")
        print("[PhotoIndexing] Average per photo: \(String(format: "%.3f", totalTime / Double(max(photoFiles.count, 1))))s")
        
        await MainActor.run {
            library.lastIndexedAt = Date()
            try? context.save()
            statusMessage = "Indexing complete!"
        }
    }
    
    private func isPhotoFile(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }
}

enum PhotoIndexingError: LocalizedError {
    case pathNotFound
    case accessDenied
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .pathNotFound:
            return "The specified path does not exist"
        case .accessDenied:
            return "Access to the path was denied"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
