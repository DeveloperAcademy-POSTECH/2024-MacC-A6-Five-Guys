//
//  BookCoverImageView.swift
//  FiveGuyes
//
//  Created by zaehorang on 8/30/25.
//

import SwiftUI

// 공용 북 커버 이미지 뷰 (플레이스홀더 포함)
struct BookCoverImageView: View {
    let coverURL: String?
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Group {
            if let coverURL, let url = URL(string: coverURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                } placeholder: {
                    Image("book_cover_placeholder")
                        .resizable()
                }
            } else {
                Rectangle()
                    .foregroundStyle(Color.Fills.white)
            }
        }
        .scaledToFit()
        .frame(width: width, height: height)
        .clipToBookShape()
        .commonShadow()
    }
}

#Preview {
    VStack(spacing: 20) {
        // 1. 실제 유효한 이미지 URL
        BookCoverImageView(
            coverURL: "https://picsum.photos/200/300",
            width: 100,
            height: 150
        )

        // 2. URL이 nil인 경우 → 플레이스홀더 표시
        BookCoverImageView(
            coverURL: nil,
            width: 100,
            height: 150
        )

        // 3. 잘못된 URL → 플레이스홀더 표시
        BookCoverImageView(
            coverURL: "invalid_url_string",
            width: 100,
            height: 150
        )
    }
    .padding()
}
