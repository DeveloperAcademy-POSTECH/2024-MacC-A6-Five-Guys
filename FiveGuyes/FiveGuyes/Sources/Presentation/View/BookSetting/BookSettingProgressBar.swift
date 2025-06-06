//
//  BookSettingProgressBar.swift
//  FiveGuyes
//
//  Created by zaehorang on 3/9/25.
//

import SwiftUI

struct BookSettingProgressBar: View {
    private let totalPages = 4  // 총 페이지 수
    var currentPage: Int = 1
    
    var body: some View {
        HStack(spacing: 4) { // 간격 추가
            ForEach(0..<totalPages, id: \.self) { index in
                Rectangle()
                    .fill(progressColor(for: index)) // 현재 페이지만 강조
                    .frame(height: 2)
                    .frame(maxWidth: .infinity) // 동일한 너비 유지
            }
        }
    }
    
    private func progressColor(for index: Int) -> Color {
        if index + 1 < currentPage {
            return Color.Colors.green // 지나온 페이지 색상
        } else if index + 1 == currentPage {
            return Color.Colors.green1 // 현재 페이지 색상
        } else {
            return Color.Separators.gray // 미래 페이지 색상
        }
    }
}

#Preview {
    BookSettingProgressBar()
}
