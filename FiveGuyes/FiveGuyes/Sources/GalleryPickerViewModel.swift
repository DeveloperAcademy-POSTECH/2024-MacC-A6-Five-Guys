//
//  CameraPicker.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/9/24.
//

import PhotosUI
import SwiftUI
import UIKit

final class GalleryPickerViewModel: ObservableObject {
    @Published var selectedGalleryPhotos: [Photo] = []
    @Published var selectedCameraSPhoto: Photo?

    func loadImagesFromPicker(_ items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        if let data = data {
                            let photo = Photo(imageData: data)
                            self.selectedGalleryPhotos.append(photo)
                        }
                    case .failure(let error):
                        print("Error loading image: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    func getCameraImage(_ image: UIImage) {
        if let imageData = image.pngData() {
            let photo = Photo(imageData: imageData)
            self.selectedCameraSPhoto = photo
        }
    }
}
