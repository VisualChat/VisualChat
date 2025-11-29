//
//  ImageEncoder.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//

import MLX
import MLXNN

//class ImageEncoder: Module, UnaryLayer {
//    let stem: Sequential
//    let stages: [Sequential]
//    let head: Linear
//    
//    let inputSize: Int = 224
//    let outputDim: Int = 512
//    
//    init() {
//        // Stem
//        let stemLayers: [UnaryLayer] = [
//            ConvBlock(inChannels: 3, outChannels: 64, kernelSize: 3, stride: 2, padding: 1),
//            ConvBlock(inChannels: 64, outChannels: 64, kernelSize: 3, stride: 1, padding: 1),
//            ConvBlock(inChannels: 64, outChannels: 64, kernelSize: 1, stride: 1, padding: 0)
//        ]
//        self.stem = Sequential(layers: stemLayers)
//        
//        // Stages (simplified version)
//        var stageList: [Sequential] = []
//        let channelProgression = [64, 128, 256, 512]
//        
//        for channels in channelProgression {
//            let blocks = Sequential(layers: [
//                ImageEncoderBlock(channels: channels),
//                ImageEncoderBlock(channels: channels)
//            ])
//            stageList.append(blocks)
//        }
//        self.stages = stageList
//        
//        // Head
//        self.head = Linear(1024, outputDim)
//        super.init()
//    }
//    
//    func callAsFunction(_ x: MLXArray) -> MLXArray {
//        var h = stem(x)
//        
//        for stage in stages {
//            h = stage(h)
//        }
//        
//        // Global average pooling
//        h = mean(h, axes: [2, 3])
//        
//        // Head projection
//        let output = head(h)
//        
//        return output
//    }
//}
