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
            coverImageURL: coverImageURL,
            publisher: publisher ?? "",
            isbn13: extractISBN13(),
            publishedDate: parsePublishedDate()
        )
    }

    private func parsePublishedDate() -> PublicationDate? {
        guard let match = datetime?.prefixMatch(of: /([0-9]{4})-([0-9]{2})-([0-9]{2})/),
              let year = Int(match.1),
              let month = Int(match.2),
              let day = Int(match.3)
        else { return nil }

        return PublicationDate(year: year, month: month, day: day)
    }

    private func extractISBN13() -> String? {
        isbn?.split(whereSeparator: \Character.isWhitespace)
            .first { $0.wholeMatch(of: /97[89][0-9]{10}/) != nil }
            .map(String.init)
    }

    private var coverImageURL: String? {
        guard let thumbnail = thumbnail?.trimmingCharacters(in: .whitespacesAndNewlines),
              !thumbnail.isEmpty
        else {
            return nil
        }
        return originalImageURL(fromThumbnail: thumbnail) ?? thumbnail
    }

    /// 썸네일의 `fname` 쿼리에 담긴 원본 주소를 https로 돌려준다. 못 읽으면 nil.
    private func originalImageURL(fromThumbnail thumbnail: String) -> String? {
        guard let fname = URLComponents(string: thumbnail)?.queryItems?
            .first(where: { $0.name == "fname" })?.value,
              var original = URLComponents(string: fname),
              let scheme = original.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              original.host?.isEmpty == false
        else {
            return nil
        }
        original.scheme = "https"
        return original.string
    }
}
