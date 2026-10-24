//
//  SDBookMetaData.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import SwiftData

@Model
final class BookMetaData {
    var title: String
    var author: String
    var coverURL: String?
    var isbn13: String?
    var totalPages: Int

    init(
        title: String,
        author: String,
        coverURL: String?,
        isbn13: String?,
        totalPages: Int
    ) {
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.isbn13 = isbn13
        self.totalPages = totalPages
    }
}
