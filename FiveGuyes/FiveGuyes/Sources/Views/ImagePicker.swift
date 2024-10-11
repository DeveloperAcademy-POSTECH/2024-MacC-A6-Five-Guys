//
//  ImagePicker.swift
//  FiveGuyes
//
//  Created by 신혜연 on 10/7/24.
//

import CoreLocation
import Photos
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let asset = info[.phAsset] as? PHAsset {
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                options.deliveryMode = .highQualityFormat
                
                PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFit, options: options) { image, _ in
                    self.parent.selectedImage = image
                    self.parent.loadMetadata(for: asset)
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

    func loadMetadata(for asset: PHAsset) {
        let options = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = { _ in false }
        
        asset.requestContentEditingInput(with: options) { input, _ in
            guard let url = input?.fullSizeImageURL else { return }
            self.processImage(at: url)
        }
    }

    private func processImage(at url: URL) {
        guard let properties = loadImageProperties(at: url) else {
            print("❌ ImagePicker/processImage: Failed to load image properties")
            return
        }
        
        let imageDate = extractImageDate(from: properties)
        processGPSInfo(from: properties, imageDate: imageDate)
    }

    private func loadImageProperties(at url: URL) -> [String: Any]? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }
        return properties
    }

    private func extractImageDate(from properties: [String: Any]) -> Date? {
        guard let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
              let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String else {
            print("❌ ImagePicker/extractImageDate: No EXIF date found")
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: dateString)
    }

    private func processGPSInfo(from properties: [String: Any], imageDate: Date?) {
        guard let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
              let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double else {
            print("❌ ImagePicker/processGPSInfo: GPS 데이터가 없습니다 - 문제 발생")
            updateMetadata(imageDate: imageDate, location: nil)
            return
        }

        Task {
            let locationName = await getLocationName(latitude: latitude, longitude: longitude)
            updateMetadata(imageDate: imageDate, location: locationName)
        }
    }

    private func updateMetadata(imageDate: Date?, location: String?) {
        DispatchQueue.main.async {
            self.imageMetadata = ImageMetadata(imageDate: imageDate, location: location)
            self.locationName = location
        }
    }
    
    private func getLocationName(latitude: Double, longitude: Double) async -> String? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        return await withCheckedContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                let fullLocationName = placemarks?.first.map { placemark in
                    [placemark.administrativeArea, placemark.locality, placemark.subLocality, placemark.name]
                        .compactMap { $0 }
                        .joined(separator: " ")
                } ?? nil
                continuation.resume(returning: fullLocationName?.trimmingCharacters(in: .whitespaces))
            }
        }
    }
}
