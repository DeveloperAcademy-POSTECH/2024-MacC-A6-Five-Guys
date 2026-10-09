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
    @Test("검색 결과를 반환한다")
    func fetchBooksReturnsProviderResult() async throws {
        let provider = BookSearchProviderStub()
        provider.fetchBooksResult = [
            BookSearchItem(
                title: "테스트 도서",
                author: "작가",
                coverImageURL: nil,
                publisher: "출판사",
                isbn13: "9781234567890",
                publishedDate: nil
            )
        ]

        let books = try await makeUseCase(provider).fetchBooks(query: "테스트")

        #expect(books.map(\.title) == ["테스트 도서"])
        #expect(provider.fetchBooksQueries == ["테스트"])
    }

    @Test("검색 provider 오류는 그대로 전파한다")
    func searchErrorIsRethrown() async {
        let provider = BookSearchProviderStub()
        provider.fetchBooksError = BookSearchError.missingAPIKey(setting: "KAKAO_API_KEY")

        await #expect(throws: BookSearchError.missingAPIKey(setting: "KAKAO_API_KEY")) {
            _ = try await makeUseCase(provider).fetchBooks(query: "설정 오류")
        }
    }

    @Test("페이지 provider 값을 반환한다")
    func totalPagesReturnsProviderResult() async {
        let provider = BookSearchProviderStub()
        provider.fetchBookTotalPagesResult = 412

        let totalPages = await makeUseCase(provider).fetchBookTotalPages(isbn: "9781234567890")

        #expect(totalPages == 412)
        #expect(provider.fetchTotalPagesISBNs == ["9781234567890"])
    }

    @Test("페이지 provider가 모름을 반환하면 0을 반환한다")
    func unknownPageCountReturnsZero() async {
        let provider = BookSearchProviderStub()
        provider.fetchBookTotalPagesResult = nil

        #expect(await makeUseCase(provider).fetchBookTotalPages(isbn: "9781234567890") == 0)
    }

    @Test("페이지 provider 오류 종류와 관계없이 0을 반환한다", arguments: [
        BookSearchError.failed,
        BookSearchError.missingAPIKey(setting: "NL_API_KEY")
    ])
    func pageCountErrorsReturnZero(error: BookSearchError) async {
        let provider = BookSearchProviderStub()
        provider.fetchBookTotalPagesError = error

        #expect(await makeUseCase(provider).fetchBookTotalPages(isbn: "9781234567890") == 0)
    }

    @Test("ISBN-13이 nil이면 페이지 provider를 호출하지 않는다")
    func missingISBN13SkipsPageProvider() async {
        let provider = BookSearchProviderStub()

        #expect(await makeUseCase(provider).fetchBookTotalPages(isbn: nil) == 0)
        #expect(provider.fetchTotalPagesISBNs.isEmpty)
    }

    private func makeUseCase(_ provider: BookSearchProviderStub) -> BookSearchUseCase {
        BookSearchUseCase(bookSearchProvider: provider, bookPageCountProvider: provider)
    }
}
