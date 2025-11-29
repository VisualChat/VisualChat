//
//  MainTabView.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//

import SwiftUI

struct MainTabView: View {
    @AppStorage("selectedTab") private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(0)
            
            PhotosView()
                .tabItem {
                    Label("Photos", systemImage: "photo.on.rectangle.angled")
                }
                .tag(1)
        }
    }
}
