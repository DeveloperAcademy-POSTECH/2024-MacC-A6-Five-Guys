//
//  ImageTestingView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/10/24.
//

import PhotosUI
import SwiftUI

struct ImageTestingView: View {
    @State private var selectedImages: [UIImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isCameraPresented = false
    @State private var cameraImage: UIImage?

    var body: some View {
        VStack {
            if !selectedImages.isEmpty || cameraImage != nil {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(selectedImages, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .cornerRadius(8)
                        }
                        if let cameraImage = cameraImage {
                            Image(uiImage: cameraImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .cornerRadius(8)
                        }
                    }
                }
            } else {
                Text("No image selected")
                    .font(.headline)
            }
            PhotosPicker(selection: $selectedItems, maxSelectionCount: 0, matching: .images) {
                Text("Select Photos")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .onChange(of: selectedItems) {
                loadImagesFromPicker(selectedItems)
            }

            Button("Open Camera") {
                isCameraPresented = true
            }
            .font(.headline)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .sheet(isPresented: $isCameraPresented) {
                CameraPickerView(selectedImage: $cameraImage, onImagePicked: { image in
                    if let image = image {
                        addImage(image)
                    }
                }, onCancel: {
                    print("Camera was canceled")
                })
            }
        }
    }

    private func loadImagesFromPicker(_ items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        if let data = data, let uiImage = UIImage(data: data) {
                            self.addImage(uiImage)
                        }
                    case .failure(let error):
                        print("Error loading image: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func addImage(_ image: UIImage) {
        selectedImages.append(image)
    }
}

#Preview {
    ImageTestingView()
}
