//
//  UnfinishReadingViewModelTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("UnfinishReadingViewModel 테스트")
@MainActor
struct UnfinishReadingViewModelTests {
    @Test("UnfinishReadingViewModel: completeBook 성공 시 true 반환")
    func unfinishReading_completeBook_success() async {
        let book = makeBook()
        let bookCompletionUseCase = BookCompletionUseCaseStub()
        let viewModel = UnfinishReadingViewModel(bookCompletionUseCase: bookCompletionUseCase)

        let completed = await viewModel.completeBook(book)

        #expect(completed)
        #expect(bookCompletionUseCase.completeBookCallCount == 1)
    }

    @Test("UnfinishReadingViewModel: 실패 시 false 반환")
    func unfinishReading_completeBook_failure() async {
        let book = makeBook()
        let bookCompletionUseCase = BookCompletionUseCaseStub()
        bookCompletionUseCase.completeBookError = TestError.forced
        let viewModel = UnfinishReadingViewModel(bookCompletionUseCase: bookCompletionUseCase)

        let completed = await viewModel.completeBook(book)

        #expect(!completed)
        #expect(bookCompletionUseCase.completeBookCallCount == 1)
    }

    @Test("UnfinishReadingViewModel: 중복 완료 요청 시 두 번째 요청 무시")
    func unfinishReading_duplicateSubmit_ignored() async {
        let book = makeBook()
        let bookCompletionUseCase = BookCompletionUseCaseStub()
        let startedSignal = AsyncSignal()
        let gate = AsyncGate()
        bookCompletionUseCase.completeBookGate = gate
        bookCompletionUseCase.onCompleteBookStart = {
            await startedSignal.signal()
        }
        let viewModel = UnfinishReadingViewModel(bookCompletionUseCase: bookCompletionUseCase)

        let firstTask = Task { await viewModel.completeBook(book) }
        await startedSignal.wait()
        let second = await viewModel.completeBook(book)
        await gate.open()
        _ = await firstTask.value

        #expect(!second)
        #expect(bookCompletionUseCase.completeBookCallCount == 1)
    }
}
