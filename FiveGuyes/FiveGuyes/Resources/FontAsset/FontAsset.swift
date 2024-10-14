//
//  FontAsset.swift
//  FiveGuyes
//
//  Created by zaehorang on 10/13/24.
//

import SwiftUI
import UIKit

import Foundation
/// 커스텀 폰트 에셋을 정의하는 구조체
/// - `font`: PretendardFont 열거형으로 선택한 폰트 스타일
/// - `fixedSize`: 폰트 크기
/// - `lineHeightPercent`: 행간을 퍼센트로 표현 (기본값 100)
/// - `kerning`: 글자 사이의 간격 (기본값 0)
struct FontAsset {
    var font: PretendardFont
    var fixedSize: CGFloat
    var lineHeightPercent: CGFloat = 100
    var kerning: CGFloat = 0
    
    /// FontAsset을 SwiftUI의 Font로 변환합니다.
    /// - Returns: 변환된 SwiftUI Font 객체
    func toFont() -> Font {
        return .custom(font.rawValue, size: fixedSize)
    }
    
    /// 텍스트의 위, 아래에 적용할 실제 폰트 간격을 계산합니다.
    /// - Returns: 위, 아래에 적용할 폰트 간격 값
    ///
    /// UIFont를 이용해 행간 퍼센트를 적용한 폰트 간격을 계산합니다.
    /// 폰트를 로드하지 못할 경우 0을 반환합니다.
    func actualFontSpacing() -> CGFloat {
        guard let uiFont = UIFont(name: font.rawValue, size: fixedSize) else {
            print("problem: \(#filePath) / \(#function)")
            return 0
        }
        let fontSpacing = (lineHeightPercent / 100 - 1) * uiFont.lineHeight / 2
        return fontSpacing
    }
}

// 자주 사용되는 폰트 스타일을 static 상수로 정의
extension FontAsset {
    static let title1 = FontAsset(font: PretendardFont.semiBold, fixedSize: 24, lineHeightPercent: 120, kerning: -0.24)
    static let title2 = FontAsset(font: PretendardFont.semiBold, fixedSize: 20, lineHeightPercent: 120, kerning: -0.2)
    static let body1 = FontAsset(font: PretendardFont.regular, fixedSize: 20, lineHeightPercent: 130, kerning: -0.2)
    static let body2 = FontAsset(font: PretendardFont.semiBold, fixedSize: 16, lineHeightPercent: 150, kerning: -0.16)
    static let caption1 = FontAsset(font: PretendardFont.medium, fixedSize: 14, lineHeightPercent: 150)
}
