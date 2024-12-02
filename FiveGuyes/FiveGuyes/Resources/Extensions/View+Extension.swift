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
