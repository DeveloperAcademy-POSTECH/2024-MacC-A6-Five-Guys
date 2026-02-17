//
//  BookSearchUseCaseTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2026-02-15.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("BookSearchUseCase 테스트")
struct BookSearchUseCaseTests {
    @Test("BookSearchUseCase.fetchBooks는 provider 결과를 그대로 반환")
    func bookSearchUseCase_fetchBooks_returnsProviderResult() async throws {
        let provider = BookSearchProviderSpy()
        provider.fetchBooksResult = [
            BookSearchItem(
                title: "테스트 도서",
                author: "작가",
                cover: nil,
                publisher: "출판사",
                isbn13: "9781234567890",
                pubDate: "20250101"
            )
        ]
        let useCase = BookSearchUseCase(bookSearchProvider: provider)

        let books = try await useCase.fetchBooks(query: "테스트")

        #expect(books.count == 1)
        #expect(books.first?.title == "테스트 도서")
        #expect(provider.fetchBooksQueries == ["테스트"])
    }

    @Test("BookSearchUseCase.fetchBooks는 provider 에러를 전파")
    func bookSearchUseCase_fetchBooks_rethrowsProviderError() async throws {
        let provider = BookSearchProviderSpy()
        provider.fetchBooksError = TestError.forced
        let useCase = BookSearchUseCase(bookSearchProvider: provider)

        await #expect(throws: TestError.self) {
            _ = try await useCase.fetchBooks(query: "실패")
        }
    }

    @Test("BookSearchUseCase.fetchBookTotalPages는 provider 값을 반환")
    func bookSearchUseCase_fetchBookTotalPages_returnsProviderResult() async throws {
        let provider = BookSearchProviderSpy()
        provider.fetchBookTotalPagesResult = 412
        let useCase = BookSearchUseCase(bookSearchProvider: provider)

        let totalPages = try await useCase.fetchBookTotalPages(isbn: "9781234567890")

        #expect(totalPages == 412)
        #expect(provider.fetchTotalPagesISBNs == ["9781234567890"])
    }
}

private final class BookSearchProviderSpy: BookSearchProviding {
    var fetchBooksResult: [BookSearchItem] = []
    var fetchBookTotalPagesResult: Int = 0

    var fetchBooksError: Error?
    var fetchBookTotalPagesError: Error?

    var fetchBooksQueries: [String] = []
    var fetchTotalPagesISBNs: [String] = []

    func fetchBooks(query: String) async throws -> [BookSearchItem] {
        fetchBooksQueries.append(query)
        if let fetchBooksError { throw fetchBooksError }
        return fetchBooksResult
    }

    func fetchBookTotalPages(isbn: String) async throws -> Int {
        fetchTotalPagesISBNs.append(isbn)
        if let fetchBookTotalPagesError { throw fetchBookTotalPagesError }
        return fetchBookTotalPagesResult
    }
}
