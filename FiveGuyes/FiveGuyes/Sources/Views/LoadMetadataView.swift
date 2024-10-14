//
//  LoadMetaData.swift
//  FiveGuyes
//
//  Created by 신혜연 on 10/14/24.
//

import CoreLocation
import Photos
import SwiftUI

struct LoadMetadataView: UIViewControllerRepresentable {
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: LoadMetadataView
        
        init(_ parent: LoadMetadataView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let asset = info[.phAsset] as? PHAsset {
                let imageLoader = ImageLoader()
                
                Task {
                    let image = await imageLoader.loadImage(for: asset)
                    self.parent.selectedImage = image
                    
                    let metadataLoader = MetadataLoader()
                    let imageMetadata = await metadataLoader.loadMetadata(for: asset)
                    self.parent.imageMetadata = imageMetadata
                    self.parent.locationName = imageMetadata?.location
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedImage: UIImage?
    @Binding var imageMetadata: ImageMetadata?
    @Binding var locationName: String?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
