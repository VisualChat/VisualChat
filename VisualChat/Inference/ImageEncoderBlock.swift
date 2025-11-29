//
//  ImageEncoderBlock.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//
import MLX
import MLXNN

//class ImageEncoderBlock: Module, UnaryLayer {
//    let tokenMixer: ConvBlock
//    let mlp: Sequential
//    let layerScale: MLXArray
//    
//    init(channels: Int) {
//        self.tokenMixer = ConvBlock(inChannels: channels, outChannels: channels, kernelSize: 3, stride: 1, padding: 1)
//        self.mlp = Sequential(layers: [
//            ConvBlock(inChannels: channels, outChannels: channels * 3, kernelSize: 1),
//            ConvBlock(inChannels: channels * 3, outChannels: channels, kernelSize: 1)
//        ])
//        self.layerScale = MLXArray.ones([channels, 1, 1]) * 0.1
//    }
//    
//    func callAsFunction(_ x: MLXArray) -> MLXArray {
//        var h = x
//        h = h + (tokenMixer(h) * layerScale)
//        h = h + (mlp(h) * layerScale)
//        return h
//    }
//}
