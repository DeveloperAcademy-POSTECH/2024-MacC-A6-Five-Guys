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

    func parsePublishedDate() -> PublicationDate? {
        guard let datetime else { return nil }

        let parts = datetime.prefix(10).split(separator: "-", omittingEmptySubsequences: false)
        guard datetime.count >= 10,
              parts.map(\.count) == [4, 2, 2],
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else { return nil }

        return PublicationDate(year: year, month: month, day: day)
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
