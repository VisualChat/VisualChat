//
//  TextEncoder.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//
import MLX
import MLXNN

//struct TextEncoder: Module, UnaryLayer {
//    let tokenEmbedding: Embedding
//    let positionalEmbedding: MLXArray
//    let transformer: [TextTransformerBlock]
//    let lnFinal: LayerNorm
//    let textProjection: Linear
//    
//    let vocabSize: Int = 49408
//    let contextLength: Int = 77
//    let hiddenSize: Int = 512
//    let numLayers: Int = 12
//    let numHeads: Int = 8
//    
//
////    init() {
////        self.tokenEmbedding = Embedding(embeddingCount: vocabSize, dimensions: hiddenSize)
////        self.positionalEmbedding = MLXArray.zeros([contextLength, hiddenSize])
////        
////        var blocks: [TextTransformerBlock] = []
////        for _ in 0..<numLayers {
////            blocks.append(TextTransformerBlock(hiddenSize: hiddenSize, numHeads: numHeads))
////        }
////        self.transformer = blocks
////        
////        self.lnFinal = LayerNorm(dimensions: hiddenSize)
////        self.textProjection = Linear(hiddenSize, hiddenSize)
////    }
//    
//    func callAsFunction(_ tokens: MLXArray) -> MLXArray {
//        let batchSize = tokens.dim(0)
//        let seqLen = tokens.dim(1)
//        
//        // Token embeddings
//        var x = tokenEmbedding(tokens)
//        
//        // Add positional embeddings
//        let posEmb = positionalEmbedding[0..<seqLen]
//        x = x + posEmb
//        
//        // Transformer blocks
//        for block in transformer {
//            x = block(x)
//        }
//        
//        // Final layer norm
//        x = lnFinal(x)
//        
//        // Take features from the eot token (last token)
//        let eotIndices = MLXArray(seqLen - 1)
//        let features = x[0..., eotIndices]
//        
//        // Project
//        let output = textProjection(features)
//        
//        return output
//    }
//}





