//
//  ImageLoader.swift
//  FiveGuyes
//
//  Created by 신혜연 on 10/14/24.
//

import Photos
import UIKit

class ImageLoader {
    func loadImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFit, options: options) { image, _ in
            completion(image)
        }
    }
}
