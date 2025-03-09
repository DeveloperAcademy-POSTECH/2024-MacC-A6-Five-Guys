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
                    .fill(index + 1 == currentPage ? Color.Colors.green1 : Color.Separators.green) // 현재 페이지만 강조
                    .frame(height: 2)
                    .frame(maxWidth: .infinity) // 동일한 너비 유지
            }
        }
    }
}

#Preview {
    BookSettingProgressBar()
}
