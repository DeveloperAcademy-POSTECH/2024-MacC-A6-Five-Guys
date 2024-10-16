//
//  CameraPickerView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/10/24.
//

import PhotosUI
import SwiftUI

struct CameraPickerView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: CameraPickerViewModel
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var viewModel: CameraPickerViewModel
        
        init(viewModel: CameraPickerViewModel) {
            self.viewModel = viewModel
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                viewModel.imagePicked(image)  // 선택된 이미지 업데이트
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            viewModel.cancel()  // 선택 취소 처리
            picker.dismiss(animated: true)
        }
    }
}
