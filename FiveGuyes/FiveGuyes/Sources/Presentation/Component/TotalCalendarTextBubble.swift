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
    var fontWeight: Font.Weight = .regular // 기본 글꼴 스타일을 regular으로 설정
    var fontSize: Font = .title2  // 기본 글자 크기를 title2로 설정

    var body: some View {
        VStack {
            Text(text)
                .foregroundStyle(textColor)
                .fontWeight(fontWeight) // fontWeight 적용
                .font(fontSize)
        }
        // 카키한테 크기 맞도록 요청
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .frame(width: 50, height: 50, alignment: .center)
        .background(backgroundColor)
        .cornerRadius(99)
    }
}
