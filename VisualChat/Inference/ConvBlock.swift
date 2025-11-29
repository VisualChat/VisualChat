//
//  ConvBlock.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//
import MLX
import MLXNN

//final class ConvBlock: Module, UnaryLayer {
//    let conv: Conv2d
//
//    init(inChannels: Int, outChannels: Int, kernelSize: Int, stride: Int = 1, padding: Int = 0) {
//        self.conv = Conv2d(
//            inputChannels: inChannels,
//            outputChannels: outChannels,
//            kernelSize: IntOrPair(kernelSize),
//            stride: IntOrPair(stride),
//            padding: IntOrPair(padding)
//        )
//        super.init()
//    }
//    
//    func callAsFunction(_ x: MLXArray) -> MLXArray {
//        return conv(x)
//    }
//}
