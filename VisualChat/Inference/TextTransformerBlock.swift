//
//  TextTransformerBlock.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//

import MLX
import MLXNN

// MARK: - Text Encoder Models
//
//class TextTransformerBlock: Module, UnaryLayer {
//    let ln1: LayerNorm
//    let attn: MultiHeadAttention
//    let ln2: LayerNorm
//    let mlp: Sequential
//    
//    init(hiddenSize: Int, numHeads: Int, mlpRatio: Int = 4) {
//        self.ln1 = LayerNorm(dimensions: hiddenSize)
//        self.attn = MultiHeadAttention(dimensions: hiddenSize, numHeads: numHeads)
//        self.ln2 = LayerNorm(dimensions: hiddenSize)
//        
//        // MLP: Linear -> GELU -> Linear
//        let hiddenDim = hiddenSize * mlpRatio
//        self.mlp = Sequential(layers: [
//            Linear(hiddenSize, hiddenDim),
//            GELU(),
//            Linear(hiddenDim, hiddenSize)
//        ])
//    }
//    
//    func callAsFunction(_ x: MLXArray, mask: MLXArray? = nil) -> MLXArray {
//        var h = x
//        let normalized = ln1(h)
//        h = h + attn(normalized, keys: normalized, values: normalized, mask: mask)
//        h = h + mlp(ln2(h))
//        return h
//    }
//}
