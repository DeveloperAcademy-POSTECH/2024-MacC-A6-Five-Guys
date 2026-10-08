//
//  BookSearchProviding.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-15.
//

enum BookSearchError: Error, Equatable {
    case missingAPIKey(setting: String)
    case network
    case invalidResponse
    case cancelled
}

protocol BookSearchProviding {
    func searchBooks(query: String) async throws -> [BookSearchItem]
}
