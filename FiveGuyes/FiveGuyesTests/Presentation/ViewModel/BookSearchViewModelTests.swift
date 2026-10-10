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
    @Test("검색 성공 시 목록을 갱신하고 검색어 앞뒤 공백을 지운다")
    func searchSuccessUpdatesBooks() async {
        let provider = BookSearchProviderStub()
        provider.fetchBooksResult = [makeBookSearchItem(title: "테스트 도서")]
        let viewModel = makeViewModel(provider: provider)

        await viewModel.searchBooks(query: "  테스트\n")

        #expect(viewModel.books.map(\.title) == ["테스트 도서"])
        #expect(provider.fetchBooksQueries == ["테스트"])
    }

    @Test("검색 실패 시 기존 목록을 유지한다")
    func searchFailureKeepsBooks() async {
        let provider = BookSearchProviderStub()
        let expectedBook = makeBookSearchItem(title: "초기 도서")
        provider.fetchBooksResult = [expectedBook]
        let viewModel = makeViewModel(provider: provider)
        await viewModel.searchBooks(query: "초기")
        provider.fetchBooksError = TestError.forced

        await viewModel.searchBooks(query: "실패")

        #expect(viewModel.books == [expectedBook])
        #expect(provider.fetchBooksQueries == ["초기", "실패"])
        #expect(!viewModel.showSearchConfigAlert)
    }

    @Test("공백뿐인 검색어는 기존 목록을 유지하고 검색하지 않는다")
    func whitespaceQueryKeepsBooksWithoutSearch() async {
        let provider = BookSearchProviderStub()
        let existingBook = makeBookSearchItem(title: "기존 도서")
        let viewModel = makeViewModel(provider: provider)
        viewModel.books = [existingBook]

        await viewModel.searchBooks(query: " \n\t ")

        #expect(viewModel.books == [existingBook])
        #expect(provider.fetchBooksQueries.isEmpty)
    }

    @Test("새 검색 결과에 없어도 기존 선택을 유지한다")
    func newSearchKeepsPreviousSelection() async {
        let provider = BookSearchProviderStub()
        let selectedBook = makeBookSearchItem(title: "선택한 도서")
        provider.fetchBooksResult = [makeBookSearchItem(title: "새 결과")]
        let viewModel = makeViewModel(provider: provider)
        viewModel.selectBook(selectedBook)

        await viewModel.searchBooks(query: "새 검색")

        #expect(viewModel.books.map(\.title) == ["새 결과"])
        #expect(viewModel.selectedBook == selectedBook)
    }

    @Test("검색 키가 없으면 설정 이름을 포함한 안내를 노출한다")
    func missingSearchAPIKeyShowsSettingName() async {
        let provider = BookSearchProviderStub()
        provider.fetchBooksError = BookSearchError.missingAPIKey(setting: "KAKAO_API_KEY")
        let viewModel = makeViewModel(provider: provider)

        await viewModel.searchBooks(query: "설정 오류")

        #expect(viewModel.showSearchConfigAlert)
        #expect(
            viewModel.searchConfigAlertMessage
                == "검색 기능 설정(KAKAO_API_KEY)이 누락되었어요. 앱 설정을 확인한 뒤 다시 시도해주세요."
        )
    }

    @Test("총 페이지 조회 성공 시 문자열을 반환한다")
    func fetchTotalPagesSuccess() async {
        let provider = BookSearchProviderStub()
        provider.fetchBookTotalPagesResult = 412
        let viewModel = makeViewModel(provider: provider)

        let totalPages = await viewModel.fetchBookTotalPages(isbn: "9781234567890")

        #expect(totalPages == "412")
        #expect(provider.fetchTotalPagesISBNs == ["9781234567890"])
    }

    @Test("페이지 조회 실패에도 선택 완료 결과를 0쪽으로 반환한다")
    func completionContinuesWithZeroWhenPageLookupFails() async {
        let provider = BookSearchProviderStub()
        provider.fetchBookTotalPagesError = BookSearchError.failed
        let viewModel = makeViewModel(provider: provider)
        let selectedBook = makeBookSearchItem(title: "선택 도서")
        viewModel.selectBook(selectedBook)

        let selection = await viewModel.completeSelection()

        #expect(selection?.selectedBook == selectedBook)
        #expect(selection?.totalPages == 0)
        #expect(!viewModel.showSearchConfigAlert)
    }

    @Test("완료 처리 성공 시 선택 책과 페이지를 반환한다")
    func completeSelectionReturnsSelection() async {
        let provider = BookSearchProviderStub()
        provider.fetchBookTotalPagesResult = 412
        let viewModel = makeViewModel(provider: provider)
        let selectedBook = makeBookSearchItem(title: "선택 도서")
        viewModel.selectBook(selectedBook)

        let selection = await viewModel.completeSelection()

        #expect(selection?.selectedBook == selectedBook)
        #expect(selection?.totalPages == 412)
        #expect(provider.fetchTotalPagesISBNs == ["9781234567890"])
        #expect(!viewModel.isCompletingSelection)
    }

    @Test("선택한 책이 없으면 완료 처리를 시작하지 않는다")
    func completeSelectionWithoutBookReturnsNil() async {
        let provider = BookSearchProviderStub()
        let viewModel = makeViewModel(provider: provider)

        let selection = await viewModel.completeSelection()

        #expect(selection == nil)
        #expect(provider.fetchTotalPagesISBNs.isEmpty)
        #expect(!viewModel.isCompletingSelection)
    }

    @Test("완료 처리 중 중복 요청을 무시한다")
    func duplicateCompletionIsIgnored() async {
        let provider = BookSearchProviderStub()
        provider.fetchBookTotalPagesResult = 320
        let startedSignal = AsyncSignal()
        let gate = AsyncGate()
        provider.fetchBookTotalPagesGate = gate
        provider.onFetchBookTotalPagesStart = {
            await startedSignal.signal()
        }
        let viewModel = makeViewModel(provider: provider)
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
        #expect(provider.fetchTotalPagesISBNs == ["9781234567890"])
        #expect(!viewModel.isCompletingSelection)
    }

    @Test("책 선택 상태를 갱신한다")
    func selectBookUpdatesSelection() {
        let provider = BookSearchProviderStub()
        let viewModel = makeViewModel(provider: provider)
        let selectedBook = makeBookSearchItem(title: "선택 도서")

        viewModel.selectBook(selectedBook)

        #expect(viewModel.selectedBook == selectedBook)
    }

    private func makeViewModel(provider: BookSearchProviderStub) -> BookSearchViewModel {
        let useCase = BookSearchUseCase(
            bookSearchProvider: provider,
            bookPageCountProvider: provider
        )
        return BookSearchViewModel(bookSearchUseCase: useCase)
    }
}
