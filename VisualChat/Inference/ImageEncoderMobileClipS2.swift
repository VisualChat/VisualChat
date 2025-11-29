//
//  ImageEncoderMobileClipS2.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/28/25.
//

import CoreML
import CoreImage
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

#if os(macOS)
typealias PlatformImage = NSImage
#elseif os(iOS)
typealias PlatformImage = UIImage
#endif

/// Image encoder for MobileCLIP S2 using CoreML mlpackage
class ImageEncoderMobileClipS2 {
    private var model: mobileclip_s2_image?
    
    enum ImageEncoderError: Error {
        case modelNotFound
        case modelLoadFailed(Error)
        case imageProcessingFailed
        case predictionFailed(Error)
        case invalidOutput
    }
    
    /// Initialize the image encoder
    init() {}
    
    /// Load the compiled model asynchronously on a background thread
    /// - Throws: ImageEncoderError if model cannot be loaded
    func loadModel() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        print("[ImageEncoder] Starting model load...")
        
        try await Task(priority: .userInitiated) {
            let config = MLModelConfiguration()
            config.computeUnits = .all // Use all available compute units (CPU, GPU, ANE)
            do {
                let loadedModel = try mobileclip_s2_image(configuration: config)
                self.model = loadedModel
            } catch {
                throw ImageEncoderError.modelLoadFailed(error)
            }
        }.value
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("[ImageEncoder] Model loaded in \(String(format: "%.3f", timeElapsed))s")
    }
    
    /// Encode an image to its embedding vector
    /// - Parameter image: PlatformImage to encode
    /// - Returns: Array of Float values representing the image embedding
    /// - Throws: ImageEncoderError if encoding fails
    func encode(image: PlatformImage) async throws -> [Float] {
        guard let model = model else {
            throw ImageEncoderError.modelNotFound
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Run encoding on background thread with userInitiated priority
        let result = try await Task(priority: .userInitiated) {
            let preprocessStart = CFAbsoluteTimeGetCurrent()
            
            // Preprocess the image (resize and normalize)
            guard let processedCGImage = self.preprocessImage(image) else {
                throw ImageEncoderError.imageProcessingFailed
            }
            
            // Create pixel buffer input directly from CGImage
            guard let pixelBuffer = self.createPixelBuffer(from: processedCGImage) else {
                throw ImageEncoderError.imageProcessingFailed
            }
            
            let preprocessTime = CFAbsoluteTimeGetCurrent() - preprocessStart
            
            do {
                let inferenceStart = CFAbsoluteTimeGetCurrent()
                
                // Use the generated model's input structure
                let input = mobileclip_s2_imageInput(image: pixelBuffer)
                let output = try model.prediction(input: input)
                
                let inferenceTime = CFAbsoluteTimeGetCurrent() - inferenceStart
                
                // Extract the embedding from output
                let embedding = output.final_emb_1
                let floatArray = self.multiArrayToFloatArray(embedding)
                
                print("[ImageEncoder] Preprocessing: \(String(format: "%.3f", preprocessTime))s, Inference: \(String(format: "%.3f", inferenceTime))s")
                
                return floatArray
            } catch {
                throw ImageEncoderError.predictionFailed(error)
            }
        }.value
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        print("[ImageEncoder] Total encoding time: \(String(format: "%.3f", totalTime))s")
        
        return result
    }
    
    /// Encode multiple images in batch
    /// - Parameter images: Array of PlatformImages to encode
    /// - Returns: Array of embedding arrays
    /// - Throws: ImageEncoderError if encoding fails
    func encodeBatch(images: [PlatformImage]) async throws -> [[Float]] {
        var results: [[Float]] = []
        for image in images {
            let embedding = try await encode(image: image)
            results.append(embedding)
        }
        return results
    }
    
    // MARK: - Private Helper Methods
    
    /// Preprocess image for the model (resize to expected input size)
    /// Returns a CGImage directly to avoid NSImage main-thread operations
    private func preprocessImage(_ image: PlatformImage) -> CGImage? {
        // MobileCLIP typically expects 256x256 input
        let targetSize = CGSize(width: 256, height: 256)
        
        #if os(macOS)
        // Extract CGImage without triggering main thread operations
        var cgImage: CGImage?
        
        // Try to get CGImage from TIFF representation (thread-safe)
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData) {
            cgImage = bitmap.cgImage
        }
        
        guard let sourceCGImage = cgImage else {
            return nil
        }
        
        let width = Int(targetSize.width)
        let height = Int(targetSize.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }
        
        context.interpolationQuality = .high
        context.draw(sourceCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return context.makeImage()
        #elseif os(iOS)
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        let width = Int(targetSize.width)
        let height = Int(targetSize.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return context.makeImage()
        #endif
    }
    
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
    
    /// Create a CVPixelBuffer from a CGImage (thread-safe)
    private func createPixelBuffer(from cgImage: CGImage) -> CVPixelBuffer? {
        let width = cgImage.width
        let height = cgImage.height
        
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attributes as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return buffer
    }
}

// MARK: - PlatformImage Extension for Pixel Buffer Conversion

extension PlatformImage {
    func pixelBuffer() -> CVPixelBuffer? {
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attributes as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }
        
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        
        #if os(macOS)
        if let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        #elseif os(iOS)
        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        #endif
        
        return buffer
    }
}

