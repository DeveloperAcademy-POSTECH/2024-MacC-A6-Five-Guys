//
//  FontStyle.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/22/24.
//

import Foundation

/// 텍스트 스타일 속성을 정의하는 열거형
enum FontStyle {
    case title1, title2, title3, body, caption1, caption2
    
    var size: CGFloat {
        switch self {
        case .title1: return 24
        case .title2: return 20
        case .title3: return 18
        case .body: return 16
        case .caption1: return 14
        case .caption2: return 12
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .title1: return 36
        case .title2: return 30
        case .title3: return 27
        case .body: return 24
        case .caption1: return 22
        case .caption2: return 18
        }
    }

    var kerning: CGFloat {
        let kerningRatio: CGFloat = -0.022
        return kerningRatio * size
    }
}
