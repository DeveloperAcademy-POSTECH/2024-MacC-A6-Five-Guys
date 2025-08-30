//
//  ReadingBooksCarousel.swift
//  FiveGuyes
//
//  Created by zaehorang on 8/13/25.
//

import SwiftUI

struct ReadingBooksCarousel: View {
    let readingBooks: [FGUserBook]
    let today: Date
    
    @Binding var activeID: UUID?
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(readingBooks) { book in
                    ReadingBookProgressCell(
                        book: book,
                        today: today
                    )
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .safeAreaPadding(.horizontal, 16)
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $activeID)
    }
}

#Preview {
    ReadingBooksCarousel(
        readingBooks: .init(repeating: .dummy, count: 7),
        today: Date(),
        activeID: .constant(UUID())
    )
    .background(.blue)  // 프리뷰에서 흰색 카드가 보이도록 파란 배경 추가
}
