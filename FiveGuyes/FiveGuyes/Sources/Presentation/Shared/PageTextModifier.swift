//
//  PageTextModifier.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/5/25.
//

import SwiftUI

struct PageTextModifier: ViewModifier {
    var fontSize: FontStyle = .title2
    var fontWeight: FontWeight = .semibold
    var foregroundColor: Color = Color.Colors.green2
    var backgroundColor: Color = Color.Fills.lightGreen
    var cornerRadius: CGFloat = 8
    var horizontalPadding: CGFloat = 8
    var verticalPadding: CGFloat = 4

    func body(content: Content) -> some View {
        content
            .fontStyle(fontSize, weight: fontWeight)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .foregroundStyle(backgroundColor)
            )
    }
}

extension View {
    func pageTextStyle(fontSize: FontStyle = .title2) -> some View {
        self.modifier(PageTextModifier(fontSize: fontSize))
    }
}
