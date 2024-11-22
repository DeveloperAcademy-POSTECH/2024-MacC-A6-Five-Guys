//
//  FontAsset.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/22/24.
//

import SwiftUI

/// 커스텀 폰트 에셋을 정의하는 구조체
struct FontAsset {
    static let fontPrefix = "Pretendard-" // 공통 접두사

    var style: FontStyle
    var weight: FontWeight
    
    var fontName: String {
        switch weight {
        case .semibold:
            return Self.fontPrefix + "SemiBold"
        case .regular:
            return Self.fontPrefix + "Regular"
        }
    }
    
    func toFont() -> Font {
        .custom(fontName, size: style.size)
    }
    
    func actualFontSpacing() -> CGFloat {
        guard let uiFont = UIFont(name: fontName, size: style.size) else {
            fatalError("Font \(fontName) could not be loaded.")
        }
        return max((style.lineHeight - uiFont.lineHeight) / 2, 0)
    }
}
