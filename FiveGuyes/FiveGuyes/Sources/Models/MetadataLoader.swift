//
//  MetadataLoader.swift
//  FiveGuyes
//
//  Created by 신혜연 on 10/14/24.
//

import CoreLocation
import Photos

class MetadataLoader {
    func loadMetadata(for asset: PHAsset, completion: @escaping (ImageMetadata?) -> Void) {
        let options = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = { _ in false }
        
        asset.requestContentEditingInput(with: options) { input, _ in
            guard let url = input?.fullSizeImageURL else {
                completion(nil)
                return
            }
            self.processImage(at: url, completion: completion)
        }
    }

    private func processImage(at url: URL, completion: @escaping (ImageMetadata?) -> Void) {
        guard let properties = loadImageProperties(at: url) else {
            print("❌ MetadataLoader/processImage: Failed to load image properties")
            completion(nil)
            return
        }
        
        let imageDate = DateFormatter.extractImageDate(from: properties)
        LocationInfoProcessor.processGPSInfo(from: properties, imageDate: imageDate) { locationName in
            completion(ImageMetadata(imageDate: imageDate, location: locationName))
        }
    }

    private func loadImageProperties(at url: URL) -> [String: Any]? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }
        return properties
    }

}
