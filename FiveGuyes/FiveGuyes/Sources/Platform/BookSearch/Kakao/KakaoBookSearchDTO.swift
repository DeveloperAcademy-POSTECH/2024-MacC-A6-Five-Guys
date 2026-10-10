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

/// 카카오 검색 응답의 document 한 건. 필드 의미는 `services/book-search/sources.md`를 본다.
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

    /// `datetime`은 ISO 8601 시각이지만 앞의 `yyyy-MM-dd`만 달력 날짜로 쓰고 타임존 변환은 하지 않는다(spec A5).
    private func parsePublishedDate() -> PublicationDate? {
        guard let match = datetime?.prefixMatch(of: /([0-9]{4})-([0-9]{2})-([0-9]{2})/),
              let year = Int(match.1),
              let month = Int(match.2),
              let day = Int(match.3)
        else { return nil }

        return PublicationDate(year: year, month: month, day: day)
    }

    /// `isbn`은 "ISBN10 ISBN13"처럼 공백으로 나뉜 문자열이라 978/979로 시작하는 13자리를 고른다(spec A11).
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

    /// 썸네일의 `fname` 쿼리에 담긴 원본 주소를 돌려준다. 호스트가 `daumcdn.net`이면 https로 바꾼다. 못 읽으면 nil.
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
        if let host = original.host?.lowercased(), host == "daumcdn.net" || host.hasSuffix(".daumcdn.net") {
            original.scheme = "https"
        }
        return original.string
    }
}
