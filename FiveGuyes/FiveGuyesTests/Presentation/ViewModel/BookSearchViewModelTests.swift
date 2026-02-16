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
        let provider = BookSearchProviderStub()
        let useCase = BookSearchUseCase(bookSearchProvider: provider)
        let expectedBook = makeBookSearchItem(title: "테스트 도서")
        provider.fetchBooksResult = [expectedBook]
        let viewModel = BookSearchViewModel(bookSearchUseCase: useCase)

        await viewModel.searchBooks(query: "테스트")

        #expect(viewModel.books.count == 1)
        #expect(viewModel.books.first?.title == "테스트 도서")
        #expect(provider.fetchBooksQueries == ["테스트"])
    }

    @Test("BookSearchViewModel: 검색 실패 시 기존 목록 유지")
    func bookSearch_searchBooks_failure_keepsBooks() async {
        let provider = BookSearchProviderStub()
        let useCase = BookSearchUseCase(bookSearchProvider: provider)
        let expectedBook = makeBookSearchItem(title: "초기 도서")
        provider.fetchBooksResult = [expectedBook]
        let viewModel = BookSearchViewModel(bookSearchUseCase: useCase)
        await viewModel.searchBooks(query: "초기")
        provider.fetchBooksError = TestError.forced

        await viewModel.searchBooks(query: "실패")

        #expect(viewModel.books.count == 1)
        #expect(viewModel.books.first?.title == "초기 도서")
        #expect(provider.fetchBooksQueries == ["초기", "실패"])
    }

    @Test("BookSearchViewModel: 총 페이지 조회 성공 시 문자열 반환")
    func bookSearch_fetchTotalPages_success() async {
        let provider = BookSearchProviderStub()
        let useCase = BookSearchUseCase(bookSearchProvider: provider)
        provider.fetchBookTotalPagesResult = 412
        let viewModel = BookSearchViewModel(bookSearchUseCase: useCase)

        let totalPages = await viewModel.fetchBookTotalPages(isbn: "9781234567890")

        #expect(totalPages == "412")
        #expect(provider.fetchTotalPagesISBNs == ["9781234567890"])
    }

    @Test("BookSearchViewModel: 총 페이지 조회 실패 시 0 반환")
    func bookSearch_fetchTotalPages_failure_returnsZero() async {
        let provider = BookSearchProviderStub()
        let useCase = BookSearchUseCase(bookSearchProvider: provider)
        provider.fetchBookTotalPagesError = TestError.forced
        let viewModel = BookSearchViewModel(bookSearchUseCase: useCase)

        let totalPages = await viewModel.fetchBookTotalPages(isbn: "9781234567890")

        #expect(totalPages == "0")
    }

    @Test("BookSearchViewModel: 완료 처리 성공 시 선택 책과 페이지 반환")
    func bookSearch_completeSelection_success_returnsSelection() async {
        let provider = BookSearchProviderStub()
        provider.fetchBookTotalPagesResult = 412
        let useCase = BookSearchUseCase(bookSearchProvider: provider)
        let viewModel = BookSearchViewModel(bookSearchUseCase: useCase)
        let selectedBook = makeBookSearchItem(title: "선택 도서")
        viewModel.selectBook(selectedBook)

        let selection = await viewModel.completeSelection()

        #expect(selection?.selectedBook == selectedBook)
        #expect(selection?.totalPages == 412)
        #expect(provider.fetchTotalPagesISBNs == [selectedBook.isbn13])
        #expect(!viewModel.isCompletingSelection)
    }

    @Test("BookSearchViewModel: 선택된 책이 없으면 완료 처리 nil 반환")
    func bookSearch_completeSelection_withoutSelectedBook_returnsNil() async {
        let provider = BookSearchProviderStub()
        let useCase = BookSearchUseCase(bookSearchProvider: provider)
        let viewModel = BookSearchViewModel(bookSearchUseCase: useCase)

        let selection = await viewModel.completeSelection()

        #expect(selection == nil)
        #expect(provider.fetchTotalPagesISBNs.isEmpty)
        #expect(!viewModel.isCompletingSelection)
    }

    @Test("BookSearchViewModel: 완료 처리 진행 중 중복 요청 무시")
    func bookSearch_completeSelection_duplicateRequest_ignored() async {
        let provider = BookSearchProviderStub()
        provider.fetchBookTotalPagesResult = 320
        let startedSignal = AsyncSignal()
        let gate = AsyncGate()
        provider.fetchBookTotalPagesGate = gate
        provider.onFetchBookTotalPagesStart = {
            await startedSignal.signal()
        }

        let useCase = BookSearchUseCase(bookSearchProvider: provider)
        let viewModel = BookSearchViewModel(bookSearchUseCase: useCase)
        let selectedBook = makeBookSearchItem(title: "중복 방지 테스트 도서")
        viewModel.selectBook(selectedBook)

        let firstTask = Task { await viewModel.completeSelection() }
        await startedSignal.wait()

        let secondSelection = await viewModel.completeSelection()
        await gate.open()
        let firstSelection = await firstTask.value

        #expect(secondSelection == nil)
        #expect(firstSelection?.selectedBook == selectedBook)
        #expect(firstSelection?.totalPages == 320)
        #expect(provider.fetchTotalPagesISBNs == [selectedBook.isbn13])
        #expect(!viewModel.isCompletingSelection)
    }

    @Test("BookSearchViewModel: 책 선택 상태 갱신")
    func bookSearch_selectBook_updatesSelectedBook() {
        let provider = BookSearchProviderStub()
        let useCase = BookSearchUseCase(bookSearchProvider: provider)
        let viewModel = BookSearchViewModel(bookSearchUseCase: useCase)
        let selectedBook = makeBookSearchItem(title: "선택 도서")

        viewModel.selectBook(selectedBook)

        #expect(viewModel.selectedBook?.title == "선택 도서")
    }
}
