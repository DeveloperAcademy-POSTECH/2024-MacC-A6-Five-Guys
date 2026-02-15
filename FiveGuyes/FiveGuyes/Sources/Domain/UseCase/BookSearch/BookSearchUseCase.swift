//
//  BookSearchUseCase.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-16.
//

import Foundation

protocol BookSearchUsing {
    func fetchBooks(query: String) async throws -> [Book]
    func fetchBookTotalPages(isbn: String) async throws -> Int
}

struct BookSearchUseCase: BookSearchUsing {
    private let bookSearchStore: any BookSearching

    init(bookSearchStore: any BookSearching) {
        self.bookSearchStore = bookSearchStore
    }

    func fetchBooks(query: String) async throws -> [Book] {
        try await bookSearchStore.fetchBooks(query: query)
    }

    func fetchBookTotalPages(isbn: String) async throws -> Int {
        try await bookSearchStore.fetchBookTotalPages(isbn: isbn)
    }
}
