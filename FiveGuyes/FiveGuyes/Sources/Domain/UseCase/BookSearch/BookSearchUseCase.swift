//
//  BookSearchUseCase.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-16.
//

import Foundation

protocol BookSearchUsing {
    func fetchBooks(query: String) async throws -> [BookSearchItem]
    func fetchBookTotalPages(isbn: String) async throws -> Int
}

struct BookSearchUseCase: BookSearchUsing {
    private let bookSearchProvider: any BookSearchProviding

    init(bookSearchProvider: any BookSearchProviding) {
        self.bookSearchProvider = bookSearchProvider
    }

    func fetchBooks(query: String) async throws -> [BookSearchItem] {
        try await bookSearchProvider.fetchBooks(query: query)
    }

    func fetchBookTotalPages(isbn: String) async throws -> Int {
        try await bookSearchProvider.fetchBookTotalPages(isbn: isbn)
    }
}
