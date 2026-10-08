//
//  BookPageCountProviding.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

protocol BookPageCountProviding {
    func fetchTotalPages(isbn13: String) async throws -> Int?
}
