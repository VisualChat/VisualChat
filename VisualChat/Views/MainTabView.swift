//
//  MainTabView.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }
            
            PhotosView()
                .tabItem {
                    Label("Photos", systemImage: "photo.on.rectangle.angled")
                }
        }
    }
}
