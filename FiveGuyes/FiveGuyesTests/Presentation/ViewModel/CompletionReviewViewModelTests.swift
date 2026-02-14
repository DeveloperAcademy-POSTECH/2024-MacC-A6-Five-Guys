//
//  CompletionReviewViewModelTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("CompletionReviewViewModel 테스트")
@MainActor
struct CompletionReviewViewModelTests {
    @Test("CompletionReviewViewModel: 빈 입력이면 경고 표시")
    func completionReview_emptyReview_showsAlert() async {
        let service = BookManagementServiceStub()
        let viewModel = CompletionReviewViewModel(
            bookCompletionUseCase: BookCompletionStubAdapter(service: service)
        )
        viewModel.preloadReview("   ")

        let outcome = await viewModel.submit(
            userBookId: UUID(),
            isUpdateMode: false
        )

        if case .none = outcome {
            #expect(viewModel.showEmptyReviewAlert)
        } else {
            Issue.record("Expected .none for empty review")
        }
        #expect(service.completeBookCallCount == 0)
    }

    @Test("CompletionReviewViewModel: 수정 모드에서 updateCompletionReview 호출")
    func completionReview_updateMode_callsUpdateCommand() async {
        let book = makeBook(isCompleted: true)
        let service = BookManagementServiceStub(book: book)
        let viewModel = CompletionReviewViewModel(
            bookCompletionUseCase: BookCompletionStubAdapter(service: service)
        )
        viewModel.preloadReview("수정된 소감")

        let outcome = await viewModel.submit(
            userBookId: book.id,
            isUpdateMode: true
        )

        if case .popToRoot = outcome {
            #expect(service.updateCompletionReviewCallCount == 1)
            #expect(service.completeBookCallCount == 0)
        } else {
            Issue.record("Expected .popToRoot for update mode")
        }
    }

    @Test("CompletionReviewViewModel: 저장 실패 시 none 반환")
    func completionReview_failure_returnsNone() async {
        let book = makeBook(isCompleted: false)
        let service = BookManagementServiceStub(book: book)
        service.completeBookError = TestError.forced

        let viewModel = CompletionReviewViewModel(
            bookCompletionUseCase: BookCompletionStubAdapter(service: service)
        )
        viewModel.preloadReview("완독 소감")

        let outcome = await viewModel.submit(
            userBookId: book.id,
            isUpdateMode: false
        )

        if case .none = outcome {
            #expect(service.completeBookCallCount == 1)
            #expect(!viewModel.isSubmitting)
        } else {
            Issue.record("Expected .none on completion review failure")
        }
    }

    @Test("CompletionReviewViewModel: 중복 제출 시 두 번째 요청 무시")
    func completionReview_duplicateSubmit_ignored() async {
        let book = makeBook(isCompleted: false)
        let service = BookManagementServiceStub(book: book)
        let startedSignal = AsyncSignal()
        let gate = AsyncGate()
        service.completeBookGate = gate
        service.onCompleteBookStart = {
            await startedSignal.signal()
        }

        let viewModel = CompletionReviewViewModel(
            bookCompletionUseCase: BookCompletionStubAdapter(service: service)
        )
        viewModel.preloadReview("완독 소감")

        let firstTask = Task {
            await viewModel.submit(
                userBookId: book.id,
                isUpdateMode: false
            )
        }
        await startedSignal.wait()
        let second = await viewModel.submit(
            userBookId: book.id,
            isUpdateMode: false
        )
        await gate.open()
        _ = await firstTask.value

        if case .none = second {
            #expect(service.completeBookCallCount == 1)
        } else {
            Issue.record("Expected second submit to return .none while submitting")
        }
    }
}
