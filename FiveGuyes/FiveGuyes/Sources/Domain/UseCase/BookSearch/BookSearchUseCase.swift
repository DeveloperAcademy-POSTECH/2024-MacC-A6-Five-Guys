//
//  BookSearchUseCase.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-16.
//

import Foundation

protocol BookSearchUsing {
    func fetchBooks(query: String) async throws -> [BookSearchItem]
    func fetchBookTotalPages(isbn: String?) async -> Int
}

struct BookSearchUseCase: BookSearchUsing {
    private let bookSearchProvider: any BookSearchProviding
    private let bookPageCountProvider: any BookPageCountProviding

    init(
        bookSearchProvider: any BookSearchProviding,
        bookPageCountProvider: any BookPageCountProviding
    ) {
        self.bookSearchProvider = bookSearchProvider
        self.bookPageCountProvider = bookPageCountProvider
    }

    func fetchBooks(query: String) async throws -> [BookSearchItem] {
        try await bookSearchProvider.searchBooks(query: query)
    }

    func fetchBookTotalPages(isbn: String?) async -> Int {
        guard let isbn else { return 0 }
        return (try? await bookPageCountProvider.fetchTotalPages(isbn13: isbn)) ?? 0
    }
}
