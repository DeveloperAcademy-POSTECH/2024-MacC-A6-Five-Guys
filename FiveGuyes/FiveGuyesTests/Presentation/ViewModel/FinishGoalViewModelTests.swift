//
//  FinishGoalViewModelTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("FinishGoalViewModel 테스트")
@MainActor
struct FinishGoalViewModelTests {
    @Test("FinishGoalViewModel: registerBook 성공 시 true 반환")
    func finishGoal_registerBook_success() async {
        let book = makeBook()
        let service = BookManagementServiceStub(book: book)
        let viewModel = FinishGoalViewModel(bookRegistrationUseCase: BookRegistrationStubAdapter(service: service))

        let selectedBook = BookSearchItem(
            title: "테스트 도서",
            author: "작가",
            cover: nil,
            publisher: "출판사",
            isbn13: "1234567890123",
            pubDate: "20250101"
        )

        let isRegistered = await viewModel.registerBook(
            selectedBook: selectedBook,
            startPage: 1,
            targetEndPage: 300,
            startDate: makeDate("2025-01-01"),
            endDate: makeDate("2025-01-31"),
            excludedReadingDays: []
        )

        #expect(isRegistered)
        #expect(service.registerBookCallCount == 1)
    }

    @Test("FinishGoalViewModel: 등록 실패 시 false 반환")
    func finishGoal_registerBook_failure() async {
        let book = makeBook()
        let service = BookManagementServiceStub(book: book)
        service.registerBookError = TestError.forced
        let viewModel = FinishGoalViewModel(bookRegistrationUseCase: BookRegistrationStubAdapter(service: service))

        let selectedBook = BookSearchItem(
            title: "테스트 도서",
            author: "작가",
            cover: nil,
            publisher: "출판사",
            isbn13: "1234567890123",
            pubDate: "20250101"
        )

        let isRegistered = await viewModel.registerBook(
            selectedBook: selectedBook,
            startPage: 1,
            targetEndPage: 300,
            startDate: makeDate("2025-01-01"),
            endDate: makeDate("2025-01-31"),
            excludedReadingDays: []
        )

        #expect(!isRegistered)
        #expect(service.registerBookCallCount == 1)
    }

    @Test("FinishGoalViewModel: 중복 등록 시 두 번째 요청 무시")
    func finishGoal_registerBook_duplicateSubmit_ignored() async {
        let book = makeBook()
        let service = BookManagementServiceStub(book: book)
        service.registerBookDelayNanoseconds = 200_000_000
        let viewModel = FinishGoalViewModel(bookRegistrationUseCase: BookRegistrationStubAdapter(service: service))

        let selectedBook = BookSearchItem(
            title: "테스트 도서",
            author: "작가",
            cover: nil,
            publisher: "출판사",
            isbn13: "1234567890123",
            pubDate: "20250101"
        )

        let firstTask = Task {
            await viewModel.registerBook(
                selectedBook: selectedBook,
                startPage: 1,
                targetEndPage: 300,
                startDate: makeDate("2025-01-01"),
                endDate: makeDate("2025-01-31"),
                excludedReadingDays: []
            )
        }
        #expect(await waitUntil { viewModel.isSubmitting })
        let second = await viewModel.registerBook(
            selectedBook: selectedBook,
            startPage: 1,
            targetEndPage: 300,
            startDate: makeDate("2025-01-01"),
            endDate: makeDate("2025-01-31"),
            excludedReadingDays: []
        )
        _ = await firstTask.value

        #expect(!second)
        #expect(service.registerBookCallCount == 1)
    }
}
