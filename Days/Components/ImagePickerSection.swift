//
//  ImagePickerSection.swift
//  Days
//

import SwiftUI
import PhotosUI
import UIKit

struct ImagePickerSection: View {
    @Binding var selectedImage: UIImage?
    let existingImage: UIImage?
    let onImageSelected: (UIImage) -> Void
    let onImageRemoved: () -> Void
    let onCameraUnavailable: (() -> Void)?

    @State private var photosPickerItems: [PhotosPickerItem] = []
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    @State private var showFileImporter = false
    @State private var showSourceChoice = false
    @State private var cameraImage: UIImage?

    private var previewImage: UIImage? {
        selectedImage ?? existingImage
    }

    var body: some View {
        Section(header: Text("Photo")) {
            if let preview = previewImage {
                imagePreviewRow(preview)
            } else {
                addPhotoButton
            }
            validationHint
        }
        .confirmationDialog("Choose Source", isPresented: $showSourceChoice) {
            Button("Photo Library") {
                showPhotosPicker = true
            }
            Button("Take Photo") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showCamera = true
                } else {
                    onCameraUnavailable?()
                }
            }
            Button("Choose File") {
                showFileImporter = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $photosPickerItems, matching: .images)
        .onChange(of: photosPickerItems) { _, items in
            guard let firstItem = items.first else { return }
            loadPhotosPickerItem(firstItem)
            photosPickerItems = []
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView(image: $cameraImage)
        }
        .onChange(of: cameraImage) { _, newImage in
            guard let newImage else { return }
            selectedImage = newImage
            onImageSelected(newImage)
            cameraImage = nil
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.image]) { result in
            handleFileImport(result)
        }
    }

    @ViewBuilder
    private func imagePreviewRow(_ image: UIImage) -> some View {
        HStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()

            Button(role: .destructive) {
                selectedImage = nil
                onImageRemoved()
            } label: {
                Text("Remove")
            }
        }
    }

    private var addPhotoButton: some View {
        Button {
            showSourceChoice = true
        } label: {
            Label("Add Photo", systemImage: "photo.badge.plus")
        }
    }

    @ViewBuilder
    private var validationHint: some View {
        if let image = previewImage {
            let result = ImageManager.validate(image)
            switch result {
            case .tooSmall:
                Text("Image is small and may appear blurry")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .tooLarge:
                Text("Image is very large and will be compressed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            default:
                EmptyView()
            }
        }
    }

    private func loadPhotosPickerItem(_ item: PhotosPickerItem) {
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
            selectedImage = image
            onImageSelected(image)
        }
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else {
                return
            }
            selectedImage = image
            onImageSelected(image)
        case .failure:
            break
        }
    }
}
