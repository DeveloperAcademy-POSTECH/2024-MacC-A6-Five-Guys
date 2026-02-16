//
//  FontModifier.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/22/24.
//

import SwiftUI

struct FontModifier: ViewModifier {
    let fontAsset: FontAsset

    func body(content: Content) -> some View {
        let fontSpacing = fontAsset.actualFontSpacing()
        return content
            .font(fontAsset.toFont())
            .kerning(fontAsset.style.kerning)
            .lineSpacing(fontSpacing * 2)
            .padding(.vertical, fontSpacing)
    }
}
