//
//  DailyProgressViewModelTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("DailyProgressViewModel 테스트")
@MainActor
struct DailyProgressViewModelTests {
    @Test("DailyProgressViewModel: 목표 초과 입력 시 제출 차단")
    func dailyProgress_overTarget_preventsSubmit() {
        let dailyReadingUseCase = DailyReadingUseCaseStub()
        let bookCompletionUseCase = BookCompletionUseCaseStub()
        let viewModel = DailyProgressViewModel(
            dailyReadingUseCase: dailyReadingUseCase,
            bookCompletionUseCase: bookCompletionUseCase
        )
        viewModel.pagesToReadToday = 101

        let canSubmit = viewModel.requestSubmit(targetEndPage: 100)

        #expect(!canSubmit)
        #expect(viewModel.showTargetExceededAlert)
    }

    @Test("DailyProgressViewModel: 완독 결과일 때 완독 화면 이동 결과 반환")
    func dailyProgress_completedOutcome() async {
        let book = makeBook()
        let dailyReadingUseCase = DailyReadingUseCaseStub(book: book)
        let bookCompletionUseCase = BookCompletionUseCaseStub()
        let today = makeDate("2025-01-03")
        dailyReadingUseCase.todayValue = today
        dailyReadingUseCase.recordReadingResult = .completed(updatedBook: book)

        let viewModel = DailyProgressViewModel(
            dailyReadingUseCase: dailyReadingUseCase,
            bookCompletionUseCase: bookCompletionUseCase
        )
        viewModel.pagesToReadToday = 300

        let outcome = await viewModel.submit(bookId: book.id)

        switch outcome {
        case .completionCelebration(let updatedBook):
            #expect(updatedBook.id == book.id)
        default:
            Issue.record("Expected .completionCelebration, got \(outcome)")
        }
        #expect(dailyReadingUseCase.recordReadingCallCount == 1)
        #expect(bookCompletionUseCase.completeBookCallCount == 1)
        #expect(bookCompletionUseCase.completeBookInputs.first?.id == book.id)
        #expect(bookCompletionUseCase.completeBookInputs.first?.review == "")
        #expect(viewModel.today() == today)
        #expect(!viewModel.isSubmitting)
    }

    @Test("DailyProgressViewModel: 실패 시 none 반환 및 submitting 해제")
    func dailyProgress_failure_returnsNone() async {
        let book = makeBook()
        let dailyReadingUseCase = DailyReadingUseCaseStub(book: book)
        let bookCompletionUseCase = BookCompletionUseCaseStub()
        dailyReadingUseCase.recordReadingError = TestError.forced

        let viewModel = DailyProgressViewModel(
            dailyReadingUseCase: dailyReadingUseCase,
            bookCompletionUseCase: bookCompletionUseCase
        )
        viewModel.pagesToReadToday = 120

        let outcome = await viewModel.submit(bookId: book.id)

        if case .none = outcome {
            #expect(dailyReadingUseCase.recordReadingCallCount == 1)
            #expect(bookCompletionUseCase.completeBookCallCount == 0)
            #expect(!viewModel.isSubmitting)
        } else {
            Issue.record("Expected .none on failure")
        }
    }

    @Test("DailyProgressViewModel: 중복 제출 시 두 번째 요청 무시")
    func dailyProgress_duplicateSubmit_ignored() async {
        let book = makeBook()
        let dailyReadingUseCase = DailyReadingUseCaseStub(book: book)
        let bookCompletionUseCase = BookCompletionUseCaseStub()
        dailyReadingUseCase.recordReadingResult = .recorded(updatedBook: book)
        let startedSignal = AsyncSignal()
        let gate = AsyncGate()
        dailyReadingUseCase.recordReadingGate = gate
        dailyReadingUseCase.onRecordReadingStart = {
            await startedSignal.signal()
        }

        let viewModel = DailyProgressViewModel(
            dailyReadingUseCase: dailyReadingUseCase,
            bookCompletionUseCase: bookCompletionUseCase
        )
        viewModel.pagesToReadToday = 10

        let firstTask = Task {
            await viewModel.submit(bookId: book.id)
        }
        await startedSignal.wait()
        let second = await viewModel.submit(bookId: book.id)
        await gate.open()
        _ = await firstTask.value

        if case .none = second {
            #expect(dailyReadingUseCase.recordReadingCallCount == 1)
            #expect(bookCompletionUseCase.completeBookCallCount == 0)
        } else {
            Issue.record("Expected second submit to return .none while submitting")
        }
    }

    @Test("DailyProgressViewModel: recorded/dateExtended/exceedsTarget 경로에서는 완독 확정 미호출")
    func dailyProgress_nonCompletedOutcome_doesNotCallCompleteBook() async {
        let book = makeBook()
        let dailyReadingUseCase = DailyReadingUseCaseStub(book: book)
        let bookCompletionUseCase = BookCompletionUseCaseStub()
        let viewModel = DailyProgressViewModel(
            dailyReadingUseCase: dailyReadingUseCase,
            bookCompletionUseCase: bookCompletionUseCase
        )
        viewModel.pagesToReadToday = 50

        dailyReadingUseCase.recordReadingResult = .recorded(updatedBook: book)
        _ = await viewModel.submit(bookId: book.id)

        dailyReadingUseCase.recordReadingResult = .dateExtended
        _ = await viewModel.submit(bookId: book.id)

        dailyReadingUseCase.recordReadingResult = .exceedsTarget(currentTarget: 300)
        _ = await viewModel.submit(bookId: book.id)

        #expect(bookCompletionUseCase.completeBookCallCount == 0)
    }

    @Test("DailyProgressViewModel: 완독 확정 실패 시 none 반환")
    func dailyProgress_completionFinalizeFailure_returnsNone() async {
        let book = makeBook()
        let dailyReadingUseCase = DailyReadingUseCaseStub(book: book)
        let bookCompletionUseCase = BookCompletionUseCaseStub()
        dailyReadingUseCase.recordReadingResult = .completed(updatedBook: book)
        bookCompletionUseCase.completeBookError = TestError.forced

        let viewModel = DailyProgressViewModel(
            dailyReadingUseCase: dailyReadingUseCase,
            bookCompletionUseCase: bookCompletionUseCase
        )
        viewModel.pagesToReadToday = 300

        let outcome = await viewModel.submit(bookId: book.id)

        if case .none = outcome {
            #expect(dailyReadingUseCase.recordReadingCallCount == 1)
            #expect(bookCompletionUseCase.completeBookCallCount == 1)
            #expect(!viewModel.isSubmitting)
        } else {
            Issue.record("Expected .none on completion finalize failure")
        }
    }
}
