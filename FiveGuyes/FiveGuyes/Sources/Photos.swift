//
//  Photos.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/10/24.
//

import UIKit

struct Photo {
    let imageData: Data
    var uiImage: UIImage? {
        return UIImage(data: imageData)
    }
    // 메타데이터 추가가능 합니다
}
