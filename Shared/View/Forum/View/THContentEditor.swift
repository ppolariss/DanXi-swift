import SwiftUI
import PhotosUI

struct THContentEditor: View {
    @Binding var content: String
    @State private var photo: PhotosPickerItem? = nil
    @State private var showUploadError = false
    @State private var showStickers = false
    @State private var showPreview = false
    
    private func uploadPhoto(_ photo: PhotosPickerItem?) async throws {
        guard let photo = photo,
              let imageData = try await photo.loadTransferable(type: Data.self) else {
            return
        }
        
        let taskID = UUID().uuidString
        content.append("![Uploading \(taskID)...]")
        let imageURL = try await THRequests.uploadImage(imageData)
        content.replace("![Uploading \(taskID)...]", with: "![](\(imageURL.absoluteString))")
    }
    
    var body: some View {
        Picker(selection: $showPreview) {
            Text("Edit").tag(false)
            Text("Preview").tag(true)
        }
        .pickerStyle(.segmented)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(.zero)
        
        if showPreview {
            Section {
                THFloorContent(content, interactable: false)
            }
        } else {
            Section {
                PhotosPicker(selection: $photo, matching: .images) {
                    Label("Upload Image", systemImage: "photo")
                }
                .onChange(of: photo) { photo in
                    Task {
                        do {
                            try await uploadPhoto(photo)
                        } catch {
                            showUploadError = true
                        }
                    }
                }
                .alert("Upload Image Failed", isPresented: $showUploadError) { }
                
                Button {
                    showStickers = true
                } label: {
                    Label("Stickers", systemImage: "smiley")
                }
                .sheet(isPresented: $showStickers) {
                    stickerPicker
                }
                
                THTextEditor(text: $content, placeholder: String(localized: "Enter post content"), minHeight: 200)
                
            } footer: {
                Text("TH Edit Alert")
            }
        }
    }
    
    private var stickerPicker: some View {
        NavigationStack {
            Form {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible())]) {
                        ForEach(THSticker.allCases, id: \.self.rawValue) { sticker in
                            Button {
                                content += " ![](\(sticker.rawValue))"
                                showStickers = false
                            } label: {
                                sticker.image
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        showStickers = false
                    } label: {
                        Text("Cancel")
                    }
                }
            }
            .navigationTitle("Stickers")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    List {
        THContentEditor(content: .constant("hello ![](dx_egg)"))
    }
}
