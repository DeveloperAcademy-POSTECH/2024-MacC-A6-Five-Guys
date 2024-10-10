//
//  ImageTestingView_Photopicker.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/8/24.
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
            // Display selected images and camera image
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

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    var onImagePicked: (UIImage?) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Delegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var onImagePicked: (UIImage?) -> Void
        var onCancel: () -> Void
        
        init(onImagePicked: @escaping (UIImage?) -> Void, onCancel: @escaping () -> Void) {
            self.onImagePicked = onImagePicked
            self.onCancel = onCancel
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            onImagePicked(image)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Delegate {
        return Delegate(onImagePicked: { image in
            self.selectedImage = image
            self.presentationMode.wrappedValue.dismiss()
        }, onCancel: {
            self.presentationMode.wrappedValue.dismiss()
        })
    }
}

#Preview {
    ImageTestingView()
}
