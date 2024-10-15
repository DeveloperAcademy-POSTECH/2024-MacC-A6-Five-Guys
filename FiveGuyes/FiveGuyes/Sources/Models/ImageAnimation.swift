//
//  ImageAnimation.swift
//  FiveGuyes
//
//  Created by zaehorang on 10/10/24.
//

import SwiftUI

/// 뷰에 적용할 다양한 애니메이션 타입을 정의하는 열거형입니다.
enum ImageAnimation {
    case movedBy(CGFloat)
    case scale(from: CGFloat, to: CGFloat)
    
    /// 선택된 애니메이션을 주어진 뷰에 적용합니다.
    /// - Parameters:
    ///   - view: 애니메이션을 적용할 SwiftUI 뷰입니다.
    ///   - isAnimating: 애니메이션을 활성화할지 여부를 나타내는 불리언 값입니다.
    /// - Returns: 선택된 애니메이션이 적용된 수정된 뷰를 반환합니다.
    @ViewBuilder
    func applyAnimation(to view: some View, isAnimating: Bool) -> some View {
        switch self {
        case .movedBy(let distance):
            view
                .offset(x: isAnimating ? distance / 2 : 0)
                .animation(.linear(duration: 2), value: isAnimating)
        case .scale(let initialScale, let finalScale):
            view
                .scaleEffect(isAnimating ? finalScale : initialScale)
        }
    }
}
