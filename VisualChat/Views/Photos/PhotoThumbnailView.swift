//
//  PhotoThumbnailView.swift
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

struct PhotoThumbnailView: View {
    let photo: Photo
    #if os(macOS)
    @State private var thumbnail: NSImage?
    #elseif os(iOS)
    @State private var thumbnail: UIImage?
    #endif
    
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
            if let thumbnail = thumbnail {
                #if os(macOS)
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipped()
                    .cornerRadius(8)
                #elseif os(iOS)
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipped()
                    .cornerRadius(8)
                #endif
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 150)
                    .cornerRadius(8)
                    .overlay {
                        ProgressView()
                    }
            }
            
            Text(photo.fileName)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 150)
        }
        .task {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let filePath = photo.filePath
        
        Task(priority: .utility) {
            // Request security-scoped access if needed
            let scopedURL = requestAccessIfNeeded()
            
            defer {
                #if os(macOS)
                scopedURL?.stopAccessingSecurityScopedResource()
                #endif
            }
            
            // Load and process image using CGImage (thread-safe)
            #if os(macOS)
            let thumbnailImage = await Task.detached { () -> NSImage? in
                let url = URL(fileURLWithPath: filePath)
                
                let options: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 1024
                ]
                
                guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
                    return nil
                }
                
                let targetSize = CGSize(width: 300, height: 300)
                let imageWidth = CGFloat(cgImage.width)
                let imageHeight = CGFloat(cgImage.height)
                
                // Calculate scale to fill the target size
                let scaleWidth = targetSize.width / imageWidth
                let scaleHeight = targetSize.height / imageHeight
                let scale = max(scaleWidth, scaleHeight)
                
                // Calculate scaled dimensions
                let scaledWidth = imageWidth * scale
                let scaledHeight = imageHeight * scale
                
                // Calculate center crop rect
                let x = (targetSize.width - scaledWidth) / 2
                let y = (targetSize.height - scaledHeight) / 2
                
                // Create bitmap context
                guard let context = CGContext(
                    data: nil,
                    width: Int(targetSize.width),
                    height: Int(targetSize.height),
                    bitsPerComponent: 8,
                    bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ) else {
                    return nil
                }
                
                // Draw the image centered and scaled
                context.interpolationQuality = .high
                context.draw(cgImage, in: CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight))
                
                // Create CGImage from context
                guard let thumbnailCGImage = context.makeImage() else {
                    return nil
                }
                
                // Convert to NSImage
                return NSImage(cgImage: thumbnailCGImage, size: targetSize)
            }.value
            #elseif os(iOS)
            let thumbnailImage = await Task.detached { () -> UIImage? in
                let url = URL(fileURLWithPath: filePath)
                
                let options: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 1024
                ]
                
                guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
                    return nil
                }
                
                let targetSize = CGSize(width: 300, height: 300)
                let imageWidth = CGFloat(cgImage.width)
                let imageHeight = CGFloat(cgImage.height)
                
                // Calculate scale to fill the target size
                let scaleWidth = targetSize.width / imageWidth
                let scaleHeight = targetSize.height / imageHeight
                let scale = max(scaleWidth, scaleHeight)
                
                // Calculate scaled dimensions
                let scaledWidth = imageWidth * scale
                let scaledHeight = imageHeight * scale
                
                // Calculate center crop rect
                let x = (targetSize.width - scaledWidth) / 2
                let y = (targetSize.height - scaledHeight) / 2
                
                // Create bitmap context
                guard let context = CGContext(
                    data: nil,
                    width: Int(targetSize.width),
                    height: Int(targetSize.height),
                    bitsPerComponent: 8,
                    bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ) else {
                    return nil
                }
                
                // Draw the image centered and scaled
                context.interpolationQuality = .high
                context.draw(cgImage, in: CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight))
                
                // Create CGImage from context
                guard let thumbnailCGImage = context.makeImage() else {
                    return nil
                }
                
                // Convert to UIImage
                return UIImage(cgImage: thumbnailCGImage)
            }.value
            #endif
            
            // Update on main thread
            await MainActor.run {
                self.thumbnail = thumbnailImage
            }
        }
    }
}
