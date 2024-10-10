//
//  CameraPicker.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/9/24.
//


import PhotosUI
import SwiftUI
import UIKit

// model 과 로직을 하나로 통일 - ObservableObject로 Store폴더에 정리
class PhotoPickerViewModel: ObservableObject {
    @Published var selectedImages: [UIImage] = []

    // Append the selected image logic
    func appendImage(_ image: UIImage) {
        self.selectedImages.append(image)
    }

    func loadImagesFromPicker(_ items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        if let data = data, let uiImage = UIImage(data: data) {
                            self.selectedImages.append(uiImage)
                        }
                    case .failure(let error):
                        print("Error loading image: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
