//
//  KakaoBookSearchDTO.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

import Foundation

struct KakaoBookSearchResponseDTO: Decodable, Sendable {
    let documents: [KakaoBookSearchDTO]
}

struct KakaoBookSearchDTO: Decodable, Sendable {
    let title: String
    let authors: [String]?
    let publisher: String?
    let datetime: String?
    let isbn: String?
    let thumbnail: String?

    func toBookSearchItem() -> BookSearchItem {
        BookSearchItem(
            title: title,
            author: authors?.joined(separator: ", ") ?? "",
            coverImageURL: nonEmptyThumbnail,
            publisher: publisher ?? "",
            isbn13: extractISBN13(),
            publishedDate: parsePublishedDate()
        )
    }

    private func parsePublishedDate() -> Date? {
        guard let datetime else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: datetime) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: datetime)
    }

    private func extractISBN13() -> String? {
        isbn?.split(whereSeparator: \Character.isWhitespace)
            .map(String.init)
            .first { value in
                value.count == 13 && value.unicodeScalars.allSatisfy {
                    (48...57).contains($0.value)
                }
            }
    }

    private var nonEmptyThumbnail: String? {
        guard let thumbnail = thumbnail?.trimmingCharacters(in: .whitespacesAndNewlines),
              !thumbnail.isEmpty
        else {
            return nil
        }
        return thumbnail
    }
}
