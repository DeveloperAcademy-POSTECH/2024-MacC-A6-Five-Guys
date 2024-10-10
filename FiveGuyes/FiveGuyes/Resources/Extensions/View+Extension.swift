//
//  View+Extension.swift
//  FiveGuyes
//
//  Created by zaehorang on 10/10/24.
//

import SwiftUI

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
