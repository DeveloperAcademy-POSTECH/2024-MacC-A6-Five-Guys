//
//  BookManagementUseCasesDailyReadingTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

extension BookManagementUseCasesTests {
    @Test("DailyReadingUseCase.recordReading으로 일반 독서 기록")
    func testRecordReadingNormal() async throws {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let today = makeDate("2025-01-02")
        let useCase = makeDailyReadingUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: ReadingDateProviderStub(todayValue: today)
        )

        let testBook = createTestBook(totalPages: 300)
        await mockRepo.setBooks([testBook])

        let result = try await useCase.recordReading(
            bookId: testBook.id,
            pagesRead: 50
        )

        switch result {
        case .recorded(let updatedBook):
            #expect(updatedBook.readingProgress.lastReadPage == 50)
            #expect(updatedBook.readingProgress.lastReadDate == today)
            let setupCount = await schedulerSpy.setupCount()
            #expect(setupCount == 1)
        default:
            Issue.record("Expected .recorded, got \(result)")
        }
    }

    @Test("DailyReadingUseCase.recordReading으로 완독 처리")
    func testRecordReadingCompletion() async throws {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let today = makeDate("2025-01-15")
        let useCase = makeDailyReadingUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: ReadingDateProviderStub(todayValue: today)
        )

        let testBook = createTestBook(totalPages: 300)
        await mockRepo.setBooks([testBook])

        let result = try await useCase.recordReading(
            bookId: testBook.id,
            pagesRead: 300
        )

        switch result {
        case .completed(let updatedBook):
            #expect(updatedBook.readingProgress.lastReadPage >= 300)
        default:
            Issue.record("Expected .completed, got \(result)")
        }
    }

    @Test("DailyReadingUseCase.recordReading으로 마지막 날 목표 미달 시 날짜 자동 연장")
    func testRecordReadingDateExtension() async throws {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let today = makeDate("2025-01-31")
        let useCase = makeDailyReadingUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: ReadingDateProviderStub(todayValue: today)
        )

        let testBook = createTestBook(totalPages: 300)
        await mockRepo.setBooks([testBook])

        let result = try await useCase.recordReading(
            bookId: testBook.id,
            pagesRead: 200
        )

        switch result {
        case .dateExtended:
            let updatedBook = try await mockRepo.fetchBook(by: testBook.id)
            #expect(updatedBook.userSettings.targetEndDate == makeDate("2025-02-01"))
            let setupCount = await schedulerSpy.setupCount()
            #expect(setupCount == 1)
        default:
            Issue.record("Expected .dateExtended, got \(result)")
        }
    }

    @Test("DailyReadingUseCase.recordReading으로 목표 페이지 초과 시 exceedsTarget 반환")
    func testRecordReadingExceedsTarget() async throws {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let today = makeDate("2025-01-15")
        let useCase = makeDailyReadingUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: ReadingDateProviderStub(todayValue: today)
        )

        let testBook = createTestBook(totalPages: 300)
        await mockRepo.setBooks([testBook])

        let result = try await useCase.recordReading(
            bookId: testBook.id,
            pagesRead: 350
        )

        switch result {
        case .exceedsTarget(let currentTarget):
            #expect(currentTarget == 300)
            let setupCount = await schedulerSpy.setupCount()
            #expect(setupCount == 0)
        default:
            Issue.record("Expected .exceedsTarget, got \(result)")
        }
    }

    @Test("DailyReadingUseCase는 내부 todayProvider 값을 읽어 recordReading 날짜로 사용")
    func testRecordReadingUsesTodayProvider() async throws {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let todayProvider = ReadingDateProviderSpy(todayValue: makeDate("2025-01-07"))
        let useCase = makeDailyReadingUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: todayProvider
        )

        let testBook = createTestBook(totalPages: 300)
        await mockRepo.setBooks([testBook])

        _ = try await useCase.recordReading(bookId: testBook.id, pagesRead: 10)

        let updatedBook = try await mockRepo.fetchBook(by: testBook.id)
        #expect(updatedBook.readingProgress.lastReadDate == makeDate("2025-01-07"))
        #expect(todayProvider.callCount == 1)
    }

    @Test("DailyReadingUseCase.recordReading은 현재 타임존을 기록에 스탬프한다")
    func testRecordReadingUsesCurrentTimeZoneID() async throws {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let today = makeDate("2025-01-07")
        let timeZoneProvider = ReadingTimeZoneProviderStub(timeZoneID: "America/Los_Angeles")
        let useCase = makeDailyReadingUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: ReadingDateProviderStub(todayValue: today),
            timeZoneProvider: timeZoneProvider
        )

        let testBook = createTestBook(totalPages: 300)
        await mockRepo.setBooks([testBook])

        _ = try await useCase.recordReading(bookId: testBook.id, pagesRead: 10)

        let updatedBook = try await mockRepo.fetchBook(by: testBook.id)
        let key = today.toYearMonthDayString()
        #expect(updatedBook.readingProgress.dailyReadingRecords[key]?.timeZoneID == "America/Los_Angeles")
    }
}
