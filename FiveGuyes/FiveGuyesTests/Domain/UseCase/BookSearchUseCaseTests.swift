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
    @Test("검색 결과를 반환하고 검색어 앞뒤 공백을 제거한다")
    func fetchBooksReturnsProviderResultWithTrimmedQuery() async throws {
        let searchProvider = BookSearchProviderSpy()
        let pageProvider = BookPageCountProviderSpy()
        searchProvider.result = [
            BookSearchItem(
                title: "테스트 도서",
                author: "작가",
                coverImageURL: nil,
                publisher: "출판사",
                isbn13: "9781234567890",
                publishedDate: nil
            )
        ]
        let useCase = makeUseCase(searchProvider: searchProvider, pageProvider: pageProvider)

        let books = try await useCase.fetchBooks(query: "  테스트\n")

        #expect(books.map(\.title) == ["테스트 도서"])
        #expect(searchProvider.queries == ["테스트"])
    }

    @Test("공백뿐인 검색어는 provider를 호출하지 않고 빈 배열을 반환한다")
    func whitespaceQuerySkipsProvider() async throws {
        let searchProvider = BookSearchProviderSpy()
        let useCase = makeUseCase(
            searchProvider: searchProvider,
            pageProvider: BookPageCountProviderSpy()
        )

        let books = try await useCase.fetchBooks(query: " \n\t ")

        #expect(books.isEmpty)
        #expect(searchProvider.queries.isEmpty)
    }

    @Test("검색 provider 오류는 그대로 전파한다")
    func searchErrorIsRethrown() async {
        let searchProvider = BookSearchProviderSpy()
        searchProvider.error = BookSearchError.missingAPIKey(setting: "KAKAO_API_KEY")
        let useCase = makeUseCase(
            searchProvider: searchProvider,
            pageProvider: BookPageCountProviderSpy()
        )

        do {
            _ = try await useCase.fetchBooks(query: "설정 오류")
            Issue.record("검색 오류가 전파되어야 합니다.")
        } catch let error as BookSearchError {
            #expect(error == .missingAPIKey(setting: "KAKAO_API_KEY"))
        } catch {
            Issue.record("예상하지 못한 오류 타입: \(error)")
        }
    }

    @Test("페이지 provider 값을 반환한다")
    func totalPagesReturnsProviderResult() async {
        let pageProvider = BookPageCountProviderSpy()
        pageProvider.result = 412
        let useCase = makeUseCase(
            searchProvider: BookSearchProviderSpy(),
            pageProvider: pageProvider
        )

        let totalPages = await useCase.fetchBookTotalPages(isbn: "9781234567890")

        #expect(totalPages == 412)
        #expect(pageProvider.isbn13Values == ["9781234567890"])
    }

    @Test("페이지 provider가 모름을 반환하면 0을 반환한다")
    func unknownPageCountReturnsZero() async {
        let pageProvider = BookPageCountProviderSpy()
        pageProvider.result = nil
        let useCase = makeUseCase(
            searchProvider: BookSearchProviderSpy(),
            pageProvider: pageProvider
        )

        #expect(await useCase.fetchBookTotalPages(isbn: "9781234567890") == 0)
    }

    @Test("페이지 provider 오류 종류와 관계없이 0을 반환한다", arguments: [
        BookSearchError.network,
        BookSearchError.invalidResponse,
        BookSearchError.cancelled,
        BookSearchError.missingAPIKey(setting: "NL_API_KEY")
    ])
    func pageCountErrorsReturnZero(error: BookSearchError) async {
        let pageProvider = BookPageCountProviderSpy()
        pageProvider.error = error
        let useCase = makeUseCase(
            searchProvider: BookSearchProviderSpy(),
            pageProvider: pageProvider
        )

        #expect(await useCase.fetchBookTotalPages(isbn: "9781234567890") == 0)
    }

    @Test("ISBN-13이 nil이거나 비어 있으면 페이지 provider를 호출하지 않는다")
    func missingISBN13SkipsPageProvider() async {
        let pageProvider = BookPageCountProviderSpy()
        let useCase = makeUseCase(
            searchProvider: BookSearchProviderSpy(),
            pageProvider: pageProvider
        )

        #expect(await useCase.fetchBookTotalPages(isbn: nil) == 0)
        #expect(await useCase.fetchBookTotalPages(isbn: " \n ") == 0)
        #expect(pageProvider.isbn13Values.isEmpty)
    }

    private func makeUseCase(
        searchProvider: BookSearchProviderSpy,
        pageProvider: BookPageCountProviderSpy
    ) -> BookSearchUseCase {
        BookSearchUseCase(
            bookSearchProvider: searchProvider,
            bookPageCountProvider: pageProvider
        )
    }
}

private final class BookSearchProviderSpy: BookSearchProviding {
    var result: [BookSearchItem] = []
    var error: Error?
    var queries: [String] = []

    func searchBooks(query: String) async throws -> [BookSearchItem] {
        queries.append(query)
        if let error { throw error }
        return result
    }
}

private final class BookPageCountProviderSpy: BookPageCountProviding {
    var result: Int?
    var error: Error?
    var isbn13Values: [String] = []

    func fetchTotalPages(isbn13: String) async throws -> Int? {
        isbn13Values.append(isbn13)
        if let error { throw error }
        return result
    }
}
