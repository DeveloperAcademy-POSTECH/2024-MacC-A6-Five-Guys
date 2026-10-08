//
//  AladinBookSearchDTO.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-15.
//

import Foundation

struct AladinSearchBookDTO: Decodable, Sendable {
    let title: String
    let author: String
    let cover: String?
    let publisher: String
    let isbn13: String
    let pubDate: String

    func toBookSearchItem() -> BookSearchItem {
        BookSearchItem(
            title: title,
            author: author,
            cover: cover,
            publisher: publisher,
            isbn13: isbn13,
            pubDate: pubDate
        )
    }
}

struct AladinBookSearchResponseDTO: Decodable, Sendable {
    let item: [AladinSearchBookDTO]
}

struct AladinBookDetailResponseDTO: Decodable, Sendable {
    let item: [AladinBookDetailDTO]?
}

struct AladinBookDetailDTO: Decodable, Sendable {
    let subInfo: AladinBookSubInfoDTO?
}

struct AladinBookSubInfoDTO: Decodable, Sendable {
    let itemPage: Int?
}
