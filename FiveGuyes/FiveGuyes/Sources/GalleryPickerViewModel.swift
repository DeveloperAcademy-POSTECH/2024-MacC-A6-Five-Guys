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
    @Published var gallerySelectedPhotos: [Photo] = []  // 선택된 갤러리 이미지
    @Published var cameraSelectedPhoto: Photo?   // 카메라에서 선택된 이미지

    func loadImagesFromPicker(_ items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        if let data = data {
                            let photo = Photo(imageData: data)
                            self.gallerySelectedPhotos.append(photo)
                        }
                    case .failure(let error):
                        print("Error loading image: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    func setCameraImage(_ image: UIImage) {
        if let imageData = image.pngData() {
            let photo = Photo(imageData: imageData)
            self.cameraSelectedPhoto = photo
        }
    }
}
