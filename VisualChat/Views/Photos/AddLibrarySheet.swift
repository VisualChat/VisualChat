//
//  AddLibrarySheet.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/27/25.
//

import SwiftUI
import AppKit

struct AddLibrarySheet: View {
    @Binding var libraryName: String
    @Binding var libraryPath: String
    var onAdd: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Photo Library")
                .font(.title)
            
            TextField("Library Name", text: $libraryName)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                TextField("Folder Path", text: $libraryPath)
                    .textFieldStyle(.roundedBorder)
                
                Button("Browse...") {
                    selectFolder()
                }
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Add & Index") {
                    onAdd()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(libraryName.trimmingCharacters(in: .whitespaces).isEmpty ||
                         libraryPath.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(30)
        .frame(width: 500)
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder to index photos from"
        panel.prompt = "Select"
        
        if panel.runModal() == .OK, let url = panel.url {
            libraryPath = url.path
            if libraryName.isEmpty {
                libraryName = url.lastPathComponent
            }
        }
    }
}
