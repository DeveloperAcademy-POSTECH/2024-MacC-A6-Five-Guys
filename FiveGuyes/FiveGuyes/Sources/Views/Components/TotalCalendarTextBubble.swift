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
    var textColor: Color = .black
    var backgroundColor: Color = Color(red: 0.84, green: 0.97, blue: 0.88)
    var fontWeight: Font.Weight = .medium // 기본 글꼴 스타일을 medium으로 설정

    var body: some View {
        VStack {
            Text(text)
                .foregroundColor(textColor)
                .fontWeight(fontWeight) // fontWeight 적용
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .frame(width: 50, height: 50, alignment: .center)
        .background(backgroundColor)
        .cornerRadius(99)
    }
}
