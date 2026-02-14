//
//  BookSearchViewModelTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("BookSearchViewModel 테스트")
@MainActor
struct BookSearchViewModelTests {
    @Test("BookSearchViewModel: 검색 성공 시 목록 갱신")
    func bookSearch_searchBooks_success_updatesBooks() async {
        let store = BookSearchStoreStub()
        let expectedBook = makeAPIBook(title: "테스트 도서")
        store.fetchBooksResult = [expectedBook]
        let viewModel = BookSearchViewModel(bookSearchStore: store)

        await viewModel.searchBooks(query: "테스트")

        #expect(viewModel.books.count == 1)
        #expect(viewModel.books.first?.title == "테스트 도서")
        #expect(store.fetchBooksQueries == ["테스트"])
    }

    @Test("BookSearchViewModel: 검색 실패 시 기존 목록 유지")
    func bookSearch_searchBooks_failure_keepsBooks() async {
        let store = BookSearchStoreStub()
        let expectedBook = makeAPIBook(title: "초기 도서")
        store.fetchBooksResult = [expectedBook]
        let viewModel = BookSearchViewModel(bookSearchStore: store)
        await viewModel.searchBooks(query: "초기")
        store.fetchBooksError = TestError.forced

        await viewModel.searchBooks(query: "실패")

        #expect(viewModel.books.count == 1)
        #expect(viewModel.books.first?.title == "초기 도서")
        #expect(store.fetchBooksQueries == ["초기", "실패"])
    }

    @Test("BookSearchViewModel: 총 페이지 조회 성공 시 문자열 반환")
    func bookSearch_fetchTotalPages_success() async {
        let store = BookSearchStoreStub()
        store.fetchBookTotalPagesResult = 412
        let viewModel = BookSearchViewModel(bookSearchStore: store)

        let totalPages = await viewModel.fetchBookTotalPages(isbn: "9781234567890")

        #expect(totalPages == "412")
        #expect(store.fetchTotalPagesISBNs == ["9781234567890"])
    }

    @Test("BookSearchViewModel: 총 페이지 조회 실패 시 0 반환")
    func bookSearch_fetchTotalPages_failure_returnsZero() async {
        let store = BookSearchStoreStub()
        store.fetchBookTotalPagesError = TestError.forced
        let viewModel = BookSearchViewModel(bookSearchStore: store)

        let totalPages = await viewModel.fetchBookTotalPages(isbn: "9781234567890")

        #expect(totalPages == "0")
    }

    @Test("BookSearchViewModel: 책 선택 상태 갱신")
    func bookSearch_selectBook_updatesSelectedBook() {
        let store = BookSearchStoreStub()
        let viewModel = BookSearchViewModel(bookSearchStore: store)
        let selectedBook = makeAPIBook(title: "선택 도서")

        viewModel.selectBook(selectedBook)

        #expect(viewModel.selectedBook?.title == "선택 도서")
    }
}
