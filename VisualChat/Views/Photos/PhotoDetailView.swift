//
//  PhotoDetailView.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//

import SwiftUI
import AppKit

struct PhotoDetailView: View {
    let photo: Photo
    @State private var image: NSImage?
    @Environment(\.dismiss) private var dismiss
    
    private func requestAccessIfNeeded() -> URL? {
        guard let library = photo.library,
              let bookmarkData = library.securityBookmark else {
            return nil
        }
        
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if url.startAccessingSecurityScopedResource() {
                return url
            }
        } catch {
            print("Failed to resolve bookmark: \(error)")
        }
        
        return nil
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(photo.fileName)
                    .font(.headline)
                Spacer()
                Button("Close") {
                    dismiss()
                }
            }
            .padding()
            
            if let image = image {
                GeometryReader { geometry in
                    ScrollView([.horizontal, .vertical]) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    }
                }
            } else {
                ProgressView()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Path: \(photo.filePath)")
                    .font(.caption)
                Text("Size: \(ByteCountFormatter.string(fromByteCount: photo.fileSize, countStyle: .file))")
                    .font(.caption)
                Text("Modified: \(photo.modifiedAt, format: .dateTime)")
                    .font(.caption)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 600, minHeight: 400)
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        // Request security-scoped access if needed
        let scopedURL = requestAccessIfNeeded()
        
        defer {
            scopedURL?.stopAccessingSecurityScopedResource()
        }
        
        let filePath = photo.filePath
        let loadedImage = await Task.detached(priority: .userInitiated) {
            let url = URL(fileURLWithPath: filePath)
            return NSImage(contentsOf: url)
        }.value
        
        if let loadedImage = loadedImage {
            image = loadedImage
        } else {
            print("Failed to load image from: \(filePath)")
        }
    }
}
