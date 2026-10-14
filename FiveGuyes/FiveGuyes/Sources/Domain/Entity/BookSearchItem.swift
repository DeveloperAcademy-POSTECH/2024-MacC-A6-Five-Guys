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
    let coverImageURL: String?
    let publisher: String
    let isbn13: String?
    let publishedDate: PublicationDate?

    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        coverImageURL: String?,
        publisher: String,
        isbn13: String?,
        publishedDate: PublicationDate?
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.coverImageURL = coverImageURL
        self.publisher = publisher
        self.isbn13 = isbn13
        self.publishedDate = publishedDate
    }
}
