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
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        return try await bookSearchProvider.searchBooks(query: trimmedQuery)
    }

    func fetchBookTotalPages(isbn: String?) async -> Int {
        guard let isbn = isbn?.trimmingCharacters(in: .whitespacesAndNewlines),
              !isbn.isEmpty else {
            return 0
        }

        do {
            return try await bookPageCountProvider.fetchTotalPages(isbn13: isbn) ?? 0
        } catch {
            return 0
        }
    }
}
