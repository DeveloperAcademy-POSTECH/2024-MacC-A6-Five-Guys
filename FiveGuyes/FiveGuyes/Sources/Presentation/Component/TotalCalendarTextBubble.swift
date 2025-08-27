//
//  TotalCalendarTextBubble.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/8/24.
//

// 전체 캘린더를 위한 버블
import SwiftUI

struct TotalCalendarTextBubble: View {
    var text: String
    var textColor: Color = Color.Labels.primaryBlack1
    var backgroundColor: Color = Color.Colors.green
    let fontWeight: Font.Weight = .regular
    let fontSize: Font = .title2

    var body: some View {
        VStack {
            Text(text)
                .foregroundStyle(textColor)
                .fontWeight(fontWeight) // fontWeight 적용
                .font(fontSize)
        }
        .frame(width: 47, height: 47, alignment: .center)
        .background(backgroundColor)
        .cornerRadius(99)
    }
}
