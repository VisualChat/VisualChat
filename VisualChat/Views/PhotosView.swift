//
//  PhotosView.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//

import SwiftUI
import SwiftData

struct PhotosView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PhotoLibrary.createdAt, order: .reverse)
    private var libraries: [PhotoLibrary]
    
    @State private var selectedLibrary: PhotoLibrary?
    @State private var showingAddLibrary = false
    @State private var newLibraryPath = ""
    @State private var newLibraryName = ""
    @StateObject private var indexingService = PhotoIndexingService()
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with photo libraries
            VStack {
                List(selection: $selectedLibrary) {
                    ForEach(libraries) { library in
                        Button {
                            selectedLibrary = library
                        } label: {
                            VStack(alignment: .leading) {
                                Text(library.name)
                                    .font(.headline)
                                Text(library.path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                if let lastIndexed = library.lastIndexedAt {
                                    Text("Last indexed: \(lastIndexed, format: .relative(presentation: .named))")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                Text("\(library.photos.count) photos")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .tag(library)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteLibrary(library)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                Task {
                                    await reindexLibrary(library)
                                }
                            } label: {
                                Label("Reindex", systemImage: "arrow.clockwise")
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button {
                                Task {
                                    await reindexLibrary(library)
                                }
                            } label: {
                                Label("Reindex", systemImage: "arrow.clockwise")
                            }
                            
                            Button(role: .destructive) {
                                deleteLibrary(library)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .navigationTitle("Photo Libraries")
                
                Button {
                    showingAddLibrary = true
                } label: {
                    Label("Add Library", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        } detail: {
            // Detail view with photo grid
            if let library = selectedLibrary {
                PhotoGridView(library: library)
            } else {
                ContentUnavailableView(
                    "Select a Library",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Choose a photo library from the sidebar or create a new one")
                )
            }
        }
        .sheet(isPresented: $showingAddLibrary) {
            AddLibrarySheet(
                libraryName: $newLibraryName,
                libraryPath: $newLibraryPath,
                onAdd: {
                    Task {
                        await addLibrary()
                    }
                }
            )
        }
        .overlay {
            if indexingService.isIndexing {
                ProgressOverlay(
                    progress: indexingService.progress,
                    message: indexingService.statusMessage
                )
            }
        }
    }
    
    private func addLibrary() async {
        let name = newLibraryName.trimmingCharacters(in: .whitespaces)
        let path = newLibraryPath.trimmingCharacters(in: .whitespaces)
        
        guard !name.isEmpty && !path.isEmpty else { return }
        
        // Create security-scoped bookmark for persistent access
        let url = URL(fileURLWithPath: path)
        var bookmarkData: Data?
        
        do {
            bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            print("Failed to create bookmark: \(error)")
        }
        
        let library = PhotoLibrary(path: path, name: name, securityBookmark: bookmarkData)
        context.insert(library)
        
        // Index photos in the background
        do {
            try await indexingService.indexPhotos(at: path, library: library, context: context)
        } catch {
            print("Error indexing photos: \(error)")
        }
        
        newLibraryName = ""
        newLibraryPath = ""
        showingAddLibrary = false
    }
    
    private func reindexLibrary(_ library: PhotoLibrary) async {
        do {
            try await indexingService.indexPhotos(at: library.path, library: library, context: context)
        } catch {
            print("Error reindexing: \(error)")
        }
    }
    
    private func deleteLibrary(_ library: PhotoLibrary) {
        if selectedLibrary?.id == library.id {
            selectedLibrary = nil
        }
        context.delete(library)
    }
}
