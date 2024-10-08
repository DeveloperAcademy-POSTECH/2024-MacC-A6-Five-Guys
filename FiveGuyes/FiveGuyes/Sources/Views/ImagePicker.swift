//
//  ImagePicker.swift
//  FiveGuyes
//
//  Created by 신혜연 on 10/7/24.
//

import ImageIO
import PhotosUI
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            // 이미지가 선택된 경우
            if let uiImage = info[.originalImage] as? UIImage,
               let url = info[.imageURL] as? URL {
                // 선택된 이미지를 parent의 이미지에 저장
                parent.selectedImage = uiImage
                parent.loadMetadata(from: url) // URL로 메타데이터 로드
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // 사용자가 선택을 취소한 경우
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedImage: UIImage?
    @Binding var imageMetadata: [String: Any]?

    // UIImagePickerController 만들기
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 업데이트가 필요하지 않음
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // 메타데이터를 가져오는 메서드
    func loadMetadata(from url: URL) {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, options) {
            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, options) as? [String: Any]
            DispatchQueue.main.async {
                self.imageMetadata = imageProperties
            }
        }
    }
}
