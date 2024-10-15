//
//  ImageLoader.swift
//  FiveGuyes
//
//  Created by 신혜연 on 10/14/24.
//

import Photos
import UIKit

class ImageLoader {
    func loadImage(for asset: PHAsset) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFit, options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
