//
//  BookSearchProviding.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-15.
//

protocol BookSearchProviding {
    func fetchBooks(query: String) async throws -> [BookSearchItem]
    func fetchBookTotalPages(isbn: String) async throws -> Int
}
