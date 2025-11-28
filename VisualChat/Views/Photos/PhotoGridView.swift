//
//  PhotoGridView.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//

import SwiftUI
import SwiftData

struct PhotoGridView: View {
    let library: PhotoLibrary
    
    @Query private var allPhotos: [Photo]
    @State private var selectedPhoto: Photo?
    @State private var searchText = ""
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]
    
    init(library: PhotoLibrary) {
        self.library = library
        // Query photos for this library, sorted by modifiedAt descending
        let libraryID = library.id
        _allPhotos = Query(
            filter: #Predicate<Photo> { photo in
                photo.library?.id == libraryID
            },
            sort: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
    }
    
    var filteredPhotos: [Photo] {
        if searchText.isEmpty {
            return allPhotos
        } else {
            return allPhotos.filter {
                $0.fileName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack {
            if allPhotos.isEmpty {
                ContentUnavailableView(
                    "No Photos",
                    systemImage: "photo.on.rectangle",
                    description: Text("This library hasn't been indexed yet or contains no photos")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredPhotos) { photo in
                            PhotoThumbnailView(photo: photo)
                                .onTapGesture {
                                    selectedPhoto = photo
                                }
                        }
                    }
                    .padding()
                }
                .searchable(text: $searchText, prompt: "Search photos")
            }
        }
        .navigationTitle(library.name)
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
        }
    }
}
