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
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else { return }
        
        var imageDate: Date?

        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
           let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            imageDate = dateFormatter.date(from: dateString)
        }
        
        processGPSInfo(from: properties, imageDate: imageDate)
    }

    private func processGPSInfo(from properties: [String: Any], imageDate: Date?) {
        if let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
           let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double,
           let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double {
            self.getLocationName(latitude: latitude, longitude: longitude) { locationName in
                DispatchQueue.main.async {
                    self.imageMetadata = ImageMetadata(imageDate: imageDate, location: locationName)
                    self.locationName = locationName
                }
            }
        } else {
            DispatchQueue.main.async {
                self.imageMetadata = ImageMetadata(imageDate: imageDate, location: nil)
                self.locationName = nil
            }
        }
    }
    
    func getLocationName(latitude: Double, longitude: Double, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            
            if let placemark = placemarks?.first {
                let administrativeArea = placemark.administrativeArea ?? ""
                let locality = placemark.locality ?? ""
                let subLocality = placemark.subLocality ?? ""
                let name = placemark.name ?? ""
                
                let fullLocationName = [administrativeArea, locality, subLocality, name]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                
                completion(fullLocationName.trimmingCharacters(in: .whitespaces))
            } else {
                completion(nil)
            }
        }
    }
}
