//
//  BookSearchTestSupport.swift
//  FiveGuyesTests
//
//  Created by Codex on 2026-10-09.
//

@testable import FiveGuyes

final class BookSearchProviderStub: BookSearchProviding, BookPageCountProviding {
    var fetchBooksResult: [BookSearchItem] = []
    var fetchBookTotalPagesResult: Int? = 0

    var fetchBooksError: Error?
    var fetchBookTotalPagesError: Error?
    var fetchBookTotalPagesDelayNanoseconds: UInt64 = 0
    var fetchBookTotalPagesGate: AsyncGate?
    var onFetchBookTotalPagesStart: (() async -> Void)?

    var fetchBooksQueries: [String] = []
    var fetchTotalPagesISBNs: [String] = []

    func searchBooks(query: String) async throws -> [BookSearchItem] {
        fetchBooksQueries.append(query)
        if let fetchBooksError { throw fetchBooksError }
        return fetchBooksResult
    }

    func fetchTotalPages(isbn13: String) async throws -> Int? {
        fetchTotalPagesISBNs.append(isbn13)
        if let onFetchBookTotalPagesStart {
            await onFetchBookTotalPagesStart()
        }
        if let fetchBookTotalPagesGate {
            await fetchBookTotalPagesGate.wait()
        }
        if fetchBookTotalPagesDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: fetchBookTotalPagesDelayNanoseconds)
        }
        if let fetchBookTotalPagesError { throw fetchBookTotalPagesError }
        return fetchBookTotalPagesResult
    }
}
