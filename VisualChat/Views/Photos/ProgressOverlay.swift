//
//  ProgressOverlay.swift
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

struct ProgressOverlay: View {
    let progress: Double
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView(value: progress) {
                    Text(message)
                }
                .progressViewStyle(.linear)
                .frame(width: 300)
                
                Text("\(Int(progress * 100))%")
                    .font(.headline)
            }
            .padding(30)
            #if os(macOS)
            .background(Color(nsColor: .windowBackgroundColor))
            #elseif os(iOS)
            .background(Color(uiColor: .systemBackground))
            #endif
            .cornerRadius(12)
            .shadow(radius: 20)
        }
    }
}
