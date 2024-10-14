//
//  View+Extension.swift
//  FiveGuyes
//
//  Created by zaehorang on 10/10/24.
//

import SwiftUI

// MARK: - View 확장: 애니메이션 적용
extension View {
    /// 뷰에 주어진 애니메이션을 적용하는 메서드.
    ///
    /// 이 메서드는 `ImageAnimation` 타입의 애니메이션을 뷰에 적용하며,
    /// `isAnimating` 플래그에 따라 애니메이션의 활성화 여부를 제어합니다.
    ///
    /// - Parameters:
    ///   - animation: 적용할 애니메이션의 타입 (`ImageAnimation`).
    ///   - isAnimating: 애니메이션이 활성화되었는지 여부를 나타내는 불리언 값.
    @ViewBuilder
    func applyAnimation(_ animation: ImageAnimation, isAnimating: Bool) -> some View {
        animation.applyAnimation(to: self, isAnimating: isAnimating)
    }
}

// MARK: - View 확장: FontAsset 적용
extension View {
    /// FontAsset을 사용하여 View에 적용합니다.
    /// - Parameter asset: 적용할 FontAsset 객체
    /// - Returns: FontAsset이 적용된 View
    ///
    /// 폰트, 행간, 패딩, 자간을 적용하여 스타일링합니다.
    func fontAsset(_ asset: FontAsset) -> some View {
        let fontSpacing = asset.actualFontSpacing()
        let lineSpacing = fontSpacing * 2
        return self
            .font(asset.toFont())
            .padding(.vertical, fontSpacing)
            .lineSpacing(lineSpacing)
            .kerning(asset.kerning)
    }
}
