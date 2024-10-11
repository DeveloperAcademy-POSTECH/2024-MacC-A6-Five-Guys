//
//  CameraPickerViewModel.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/10/24.
//

import SwiftUI
import UIKit

class CameraPickerViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    
    // 이미지 선택 시 호출
    func imagePicked(_ image: UIImage?) {
        selectedImage = image
    }
    
    // 이미지 선택 취소 시 호출
    func cancel() {
        selectedImage = nil
    }
}
