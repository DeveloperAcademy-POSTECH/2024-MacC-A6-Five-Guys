//
//  MetadataLoader.swift
//  FiveGuyes
//
//  Created by 신혜연 on 10/14/24.
//

import CoreLocation
import Photos

class MetadataLoader {
    func loadMetadata(for asset: PHAsset) async -> ImageMetadata? {
        let options = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = { _ in false }
        return await withCheckedContinuation { continuation in
            asset.requestContentEditingInput(with: options) { input, _ in
                guard let url = input?.fullSizeImageURL else {
                    continuation.resume(returning: nil)
                    return
                }
                
                Task {
                    let imageMetadata = await self.processImage(at: url)
                    continuation.resume(returning: imageMetadata)
                }
            }
        }
    }
    private func processImage(at url: URL) async -> ImageMetadata? {
        guard let properties = await loadImageProperties(at: url) else {
            print("❌ MetadataLoader/processImage: Failed to load image properties")
            return nil
        }
        
        let imageDate = await DateFormatter.extractImageDate(from: properties)
        
        let locationName = await LocationInfoProcessor.processGPSInfo(from: properties, imageDate: imageDate)
        return ImageMetadata(imageDate: imageDate, location: locationName)
    }
    
    private func loadImageProperties(at url: URL) async -> [String: Any]? {
        return await withCheckedContinuation { continuation in
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
                continuation.resume(returning: nil)
                return
            }
            continuation.resume(returning: properties)
        }
    }
}
