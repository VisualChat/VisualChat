//
//  PhotoDetailView.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//

import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

struct PhotoDetailView: View {
    let photo: Photo
    #if os(macOS)
    @State private var image: NSImage?
    #elseif os(iOS)
    @State private var image: UIImage?
    #endif
    @Environment(\.dismiss) private var dismiss
    
    private func requestAccessIfNeeded() -> URL? {
        #if os(macOS)
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
        #else
        // iOS doesn't use security-scoped bookmarks
        return nil
        #endif
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
                        #if os(macOS)
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                        #elseif os(iOS)
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                        #endif
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
            #if os(macOS)
            scopedURL?.stopAccessingSecurityScopedResource()
            #endif
        }
        
        let filePath = photo.filePath
        #if os(macOS)
        let loadedImage = await Task.detached(priority: .userInitiated) {
            let url = URL(fileURLWithPath: filePath)
            return NSImage(contentsOf: url)
        }.value
        #elseif os(iOS)
        let loadedImage = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            let url = URL(fileURLWithPath: filePath)
            guard let data = try? Data(contentsOf: url) else { return nil }
            return UIImage(data: data)
        }.value
        #endif
        
        if let loadedImage = loadedImage {
            image = loadedImage
        } else {
            print("Failed to load image from: \(filePath)")
        }
    }
}
