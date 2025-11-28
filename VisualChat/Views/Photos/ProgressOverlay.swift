//
//  ProgressOverlay.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//

import SwiftUI
import AppKit

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
            .background(Color(nsColor: .windowBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 20)
        }
    }
}
