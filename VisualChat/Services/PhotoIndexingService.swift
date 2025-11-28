//
//  PhotoIndexingService.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//

import Foundation
import SwiftData
import AppKit
internal import Combine

@MainActor
class PhotoIndexingService: ObservableObject {
    @Published var isIndexing = false
    @Published var progress: Double = 0
    @Published var statusMessage = ""
    
    private let supportedExtensions = ["jpg", "jpeg", "png", "heic", "heif", "gif", "tiff", "tif", "bmp", "webp"]
    
    func indexPhotos(at path: String, library: PhotoLibrary, context: ModelContext) async throws {
        isIndexing = true
        progress = 0
        statusMessage = "Starting indexing..."
        
        defer {
            isIndexing = false
            statusMessage = ""
        }
        
        let url = URL(fileURLWithPath: path)
        
        // Request security-scoped access if we have a bookmark
        var scopedURL: URL?
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
        
        defer {
            scopedURL?.stopAccessingSecurityScopedResource()
        }
        
        // Verify path exists on background thread
        let pathExists = await Task.detached {
            FileManager.default.fileExists(atPath: path)
        }.value
        
        guard pathExists else {
            throw PhotoIndexingError.pathNotFound
        }
        
        // Clear existing photos for this library
        for photo in library.photos {
            context.delete(photo)
        }
        
        // Get all photo files on background thread
        statusMessage = "Scanning directory..."
        let photoFiles = await Task.detached { [supportedExtensions] in
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
        
        statusMessage = "Found \(photoFiles.count) photos"
        
        // Index photos in batches to allow UI updates
        let batchSize = 10
        for batchStart in stride(from: 0, to: photoFiles.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, photoFiles.count)
            let batch = Array(photoFiles[batchStart..<batchEnd])
            
            // Process batch on background thread
            let photoData = await Task.detached {
                batch.compactMap { fileURL -> (path: String, name: String, size: Int64, date: Date)? in
                    guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]) else {
                        return nil
                    }
                    return (
                        path: fileURL.path,
                        name: fileURL.lastPathComponent,
                        size: Int64(resourceValues.fileSize ?? 0),
                        date: resourceValues.contentModificationDate ?? Date()
                    )
                }
            }.value
            
            // Insert on main actor
            for data in photoData {
                let photo = Photo(
                    filePath: data.path,
                    fileName: data.name,
                    fileSize: data.size,
                    modifiedAt: data.date,
                    library: library
                )
                context.insert(photo)
            }
            
            progress = Double(batchEnd) / Double(photoFiles.count)
            statusMessage = "Indexed \(batchEnd) of \(photoFiles.count)"
            
            // Allow UI to update between batches
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        library.lastIndexedAt = Date()
        try context.save()
        
        statusMessage = "Indexing complete!"
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
