//
//  BookCoverImageView.swift
//  FiveGuyes
//
//  Created by zaehorang on 8/30/25.
//

import SwiftUI

struct BookCoverImageView: View {
    let coverURL: String?

    enum InitialContent: Equatable {
        case remote(URL)
        case defaultCover
    }

    var body: some View {
        switch Self.initialContent(for: coverURL) {
        case let .remote(url):
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
        case .defaultCover:
            defaultCover
        }
    }

    static func initialContent(for coverURL: String?) -> InitialContent {
        guard let coverURL = coverURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !coverURL.isEmpty,
              let url = URL(string: coverURL)
        else {
            return .defaultCover
        }
        return .remote(url)
    }

    private var defaultCover: some View {
        Image("book_cover_placeholder")
            .resizable()
    }
}

#Preview {
    VStack(spacing: 20) {
        BookCoverImageView(
            coverURL: "https://picsum.photos/200/300"
        )
        .scaledToFit()
        .frame(width: 100, height: 150)
        .clipToBookShape()
        .commonShadow()

        BookCoverImageView(
            coverURL: nil
        )
        .scaledToFit()
        .frame(width: 100, height: 150)
        .clipToBookShape()
        .commonShadow()

        BookCoverImageView(
            coverURL: "invalid_url_string"
        )
        .scaledToFit()
        .frame(width: 100, height: 150)
        .clipToBookShape()
        .commonShadow()
    }
    .padding()
}
