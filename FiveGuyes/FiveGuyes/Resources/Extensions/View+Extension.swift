//
//  View+Extension.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/22/24.
//

import SwiftUI

extension View {
    /// 뷰에 `FontStyle`과 `Font.Weight`를 사용하여 커스텀 폰트 스타일을 적용합니다.
    /// ## 사용 예시
    /// ``` swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         VStack {
    ///             Text("제목 1 - SemiBold")
    ///                 .fontStyle(.title1, weight: .semibold)
    ///
    ///             Text("본문 - Regular")
    ///                 .fontStyle(.body)
    ///         }
    ///     }
    /// }
    /// ```
    func fontStyle(_ style: FontStyle, weight: FontWeight = .regular) -> some View {
        let fontAsset = FontAsset(style: style, weight: weight)
        return self.modifier(FontModifier(fontAsset: fontAsset))
    }
}

extension View {
    func commonShadow() -> some View {
        self.shadow(
            color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25),
            radius: 2,
            x: 0,
            y: 4
        )
    }
    
    /// Clips the view into a shape resembling a book with rounded corners.
    func clipToBookShape(
        bottomTrailingRadius: CGFloat = 6,
        topTrailingRadius: CGFloat = 6
    ) -> some View {
        self.clipShape(
            RoundedRectangle(cornerSize: CGSize(width: bottomTrailingRadius, height: topTrailingRadius))
        )
    }
}
