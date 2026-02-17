//
//  BookSearchItem.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-15.
//

import Foundation

struct BookSearchItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let title: String
    let author: String
    let cover: String?
    let publisher: String
    let isbn13: String
    let pubDate: String

    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        cover: String?,
        publisher: String,
        isbn13: String,
        pubDate: String
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.cover = cover
        self.publisher = publisher
        self.isbn13 = isbn13
        self.pubDate = pubDate
    }
}
