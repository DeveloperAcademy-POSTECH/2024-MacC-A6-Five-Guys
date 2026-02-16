//
//  ReadingDateEditViewModelTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("ReadingDateEditViewModel 테스트")
@MainActor
struct ReadingDateEditViewModelTests {
    @Test("ReadingDateEditViewModel: updateReadingPlan 성공 시 true 반환")
    func readingDateEdit_success() async {
        let book = makeBook()
        let readingPlanUseCase = ReadingPlanUseCaseStub()
        let today = makeDate("2025-01-02")
        readingPlanUseCase.todayValue = today
        let viewModel = ReadingDateEditViewModel(
            readingPlanUseCase: readingPlanUseCase
        )

        let isUpdated = await viewModel.submitReadingPlanUpdate(
            bookId: book.id,
            startDate: makeDate("2025-01-01"),
            endDate: makeDate("2025-01-31"),
            excludedReadingDays: []
        )

        #expect(isUpdated)
        #expect(readingPlanUseCase.updateReadingPlanCallCount == 1)
        #expect(viewModel.today() == today)
    }

    @Test("ReadingDateEditViewModel: 실패 시 false 반환")
    func readingDateEdit_failure() async {
        let book = makeBook()
        let readingPlanUseCase = ReadingPlanUseCaseStub()
        readingPlanUseCase.updateReadingPlanError = TestError.forced
        let viewModel = ReadingDateEditViewModel(
            readingPlanUseCase: readingPlanUseCase
        )

        let isUpdated = await viewModel.submitReadingPlanUpdate(
            bookId: book.id,
            startDate: makeDate("2025-01-01"),
            endDate: makeDate("2025-01-31"),
            excludedReadingDays: []
        )

        #expect(!isUpdated)
        #expect(readingPlanUseCase.updateReadingPlanCallCount == 1)
    }

    @Test("ReadingDateEditViewModel: 중복 제출 시 두 번째 요청 무시")
    func readingDateEdit_duplicateSubmit_ignored() async {
        let book = makeBook()
        let readingPlanUseCase = ReadingPlanUseCaseStub()
        readingPlanUseCase.updateReadingPlanDelayNanoseconds = 200_000_000

        let viewModel = ReadingDateEditViewModel(
            readingPlanUseCase: readingPlanUseCase
        )

        let firstTask = Task {
            await viewModel.submitReadingPlanUpdate(
                bookId: book.id,
                startDate: makeDate("2025-01-01"),
                endDate: makeDate("2025-01-31"),
                excludedReadingDays: []
            )
        }
        #expect(await waitUntil { viewModel.isSubmitting })
        let second = await viewModel.submitReadingPlanUpdate(
            bookId: book.id,
            startDate: makeDate("2025-01-01"),
            endDate: makeDate("2025-01-31"),
            excludedReadingDays: []
        )
        _ = await firstTask.value

        #expect(!second)
        #expect(readingPlanUseCase.updateReadingPlanCallCount == 1)
    }
}
