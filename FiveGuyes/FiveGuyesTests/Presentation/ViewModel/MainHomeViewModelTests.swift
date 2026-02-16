//
//  MainHomeViewModelTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("MainHomeViewModel 테스트")
@MainActor
struct MainHomeViewModelTests {
    @Test("MainHomeViewModel: 현재 읽는 책 기준으로 알림 재설정")
    func mainHome_setupNotificationsForCurrentBook() async {
        let firstBook = makeBook()
        let secondBook = makeBook()
        let notificationService = NotificationManagerStub()
        let readingLibraryUseCase = ReadingLibraryUseCaseStub(
            readingBooks: [firstBook, secondBook],
            completedBooks: [],
            notificationService: notificationService
        )
        let viewModel = MainHomeViewModel(
            readingLibraryUseCase: readingLibraryUseCase
        )

        await viewModel.loadBooks()
        await viewModel.setupNotificationsForCurrentBook()

        #expect(notificationService.setupAllNotificationsCallCount == 1)
        #expect(notificationService.setupAllNotificationsBookIDs == [firstBook.id])
    }

    @Test("MainHomeViewModel: 읽는 책이 없으면 알림 재설정 생략")
    func mainHome_setupNotificationsWithoutReadingBook() async {
        let notificationService = NotificationManagerStub()
        let readingLibraryUseCase = ReadingLibraryUseCaseStub(
            readingBooks: [],
            completedBooks: [],
            notificationService: notificationService
        )
        let viewModel = MainHomeViewModel(
            readingLibraryUseCase: readingLibraryUseCase
        )

        await viewModel.loadBooks()
        await viewModel.setupNotificationsForCurrentBook()

        #expect(notificationService.setupAllNotificationsCallCount == 0)
    }

    @Test("MainHomeViewModel: 목표일 초과 책을 재스케줄 결과로 반환")
    func mainHome_reschedule_returnsOverdueBooks() async {
        let overdueBook = makeBook()
        let today = makeDate("2025-01-15")
        let readingLibraryUseCase = ReadingLibraryUseCaseStub(
            readingBooks: [overdueBook],
            completedBooks: []
        )
        readingLibraryUseCase.todayValue = today
        readingLibraryUseCase.rescheduleOnAppOpenError = ScheduleCalculationError.targetDatePassed
        let viewModel = MainHomeViewModel(readingLibraryUseCase: readingLibraryUseCase)

        await viewModel.loadBooks()
        let overdueBooks = await viewModel.rescheduleOnAppOpen()

        #expect(overdueBooks.count == 1)
        #expect(overdueBooks.first?.id == overdueBook.id)
        #expect(readingLibraryUseCase.rescheduleOnAppOpenCallCount == 1)
        #expect(viewModel.today() == today)
    }
}
