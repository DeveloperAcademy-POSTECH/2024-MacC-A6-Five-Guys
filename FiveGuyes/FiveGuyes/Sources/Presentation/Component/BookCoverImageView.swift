//
//  BookCoverImageView.swift
//  FiveGuyes
//
//  Created by zaehorang on 8/30/25.
//

import SwiftUI

struct BookCoverImageView: View {
    let coverURL: String?

    var body: some View {
        if let url = Self.url(from: coverURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case let .success(image):
                    image.resizable()
                case .failure:
                    defaultCover
                @unknown default:
                    defaultCover
                }
            }
        } else {
            defaultCover
        }
    }

    static func url(from coverURL: String?) -> URL? {
        guard let coverURL = coverURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !coverURL.isEmpty,
              let url = URL(string: coverURL)
        else {
            return nil
        }
        return url
    }

    private var defaultCover: some View {
        Image("book_cover_placeholder")
            .resizable()
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(["https://picsum.photos/200/300", nil, "invalid_url_string"] as [String?], id: \.self) { url in
            BookCoverImageView(coverURL: url)
                .scaledToFit()
                .frame(width: 100, height: 150)
                .clipToBookShape()
                .commonShadow()
        }
    }
    .padding()
}
