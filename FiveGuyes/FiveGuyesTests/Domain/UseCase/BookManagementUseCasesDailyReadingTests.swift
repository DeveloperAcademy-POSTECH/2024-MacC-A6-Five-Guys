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

    @Test("DailyReadingUseCase.recordReading으로 시작일 이전 기록 시 시작일부터 재분배")
    func testRecordReadingBeforeStartDateRecalculateFromStartDate() async throws {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let today = makeDate("2025-01-15")
        let useCase = makeDailyReadingUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: ReadingDateProviderStub(todayValue: today)
        )

        var testBook = createTestBook(totalPages: 100)
        testBook.userSettings = FGUserSetting(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-20"),
            targetEndDate: makeDate("2025-01-24"),
            excludedReadingDays: []
        )
        testBook.readingProgress = try ReadingScheduleCalculator().createInitialSchedule(settings: testBook.userSettings)
        await mockRepo.setBooks([testBook])

        let result = try await useCase.recordReading(
            bookId: testBook.id,
            pagesRead: 30
        )

        switch result {
        case .recorded(let updatedBook):
            #expect(updatedBook.userSettings.startDate == makeDate("2025-01-20"))
            #expect(updatedBook.readingProgress.lastReadPage == 30)

            let records = updatedBook.readingProgress.dailyReadingRecords
            #expect(records["2025-01-15"]?.targetPages == 30)
            #expect(records["2025-01-16"] == nil)
            #expect(records["2025-01-19"] == nil)
            #expect(records["2025-01-20"]?.targetPages == 44)
            #expect(records["2025-01-24"]?.targetPages == 100)

            let setupCount = await schedulerSpy.setupCount()
            #expect(setupCount == 1)
        default:
            Issue.record("Expected .recorded, got \(result)")
        }
    }

    @Test("DailyReadingUseCase.recordReading으로 재할당 계산 불가 시 에러 전파")
    func testRecordReadingRecalculationFailurePropagatesError() async throws {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let today = makeDate("2025-01-15")
        let useCase = makeDailyReadingUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: ReadingDateProviderStub(todayValue: today)
        )

        var testBook = createTestBook(totalPages: 100)
        testBook.userSettings = FGUserSetting(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-20"),
            targetEndDate: makeDate("2025-01-20"),
            excludedReadingDays: [makeDate("2025-01-20")]
        )
        testBook.readingProgress = FGReadingProgress(
            dailyReadingRecords: [:],
            lastReadDate: nil,
            lastReadPage: 0
        )
        await mockRepo.setBooks([testBook])

        await #expect(throws: ScheduleCalculationError.self) {
            _ = try await useCase.recordReading(
                bookId: testBook.id,
                pagesRead: 10
            )
        }

        let setupCount = await schedulerSpy.setupCount()
        #expect(setupCount == 0)
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

    @Test("DailyReadingUseCase.recordReading으로 중간 날짜 조기 완독 시 completed 반환 및 미래 목표 제거")
    func testRecordReadingEarlyCompletionRemovesFutureTargets() async throws {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let today = makeDate("2025-01-11")
        let useCase = makeDailyReadingUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: ReadingDateProviderStub(todayValue: today)
        )

        var testBook = createTestBook(totalPages: 100)
        testBook.userSettings = FGUserSetting(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-14"),
            excludedReadingDays: []
        )
        testBook.readingProgress = try ReadingScheduleCalculator().createInitialSchedule(settings: testBook.userSettings)
        await mockRepo.setBooks([testBook])

        let result = try await useCase.recordReading(
            bookId: testBook.id,
            pagesRead: 100
        )

        switch result {
        case .completed(let updatedBook):
            #expect(updatedBook.readingProgress.lastReadDate == today)
            #expect(updatedBook.readingProgress.lastReadPage == 100)
            #expect(updatedBook.readingProgress.dailyReadingRecords["2025-01-10"]?.targetPages == 20)
            #expect(updatedBook.readingProgress.dailyReadingRecords["2025-01-11"]?.targetPages == 100)
            #expect(updatedBook.readingProgress.dailyReadingRecords["2025-01-11"]?.pagesRead == 100)
            #expect(updatedBook.readingProgress.dailyReadingRecords["2025-01-12"] == nil)
            #expect(updatedBook.readingProgress.dailyReadingRecords["2025-01-14"] == nil)
            #expect(updatedBook.readingProgress.dailyReadingRecords.count == 2)

            let setupCount = await schedulerSpy.setupCount()
            #expect(setupCount == 1)
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
