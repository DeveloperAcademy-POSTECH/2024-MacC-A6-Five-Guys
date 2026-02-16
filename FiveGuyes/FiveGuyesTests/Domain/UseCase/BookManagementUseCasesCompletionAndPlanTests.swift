//
//  BookManagementUseCasesCompletionAndPlanTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

extension BookManagementUseCasesTests {
    @Test("BookCompletionUseCase.completeBook으로 정상 완독 처리")
    func testCompleteBook() async throws {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let completionDate = makeDate("2025-01-20")
        let useCase = makeBookCompletionUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: ReadingDateProviderStub(todayValue: completionDate)
        )

        let testBook = createTestBook(totalPages: 300, isCompleted: false)
        await mockRepo.setBooks([testBook])

        let review = "좋은 책이었습니다!"
        try await useCase.completeBook(
            id: testBook.id,
            review: review
        )

        let updatedBook = try await mockRepo.fetchBook(by: testBook.id)
        let clearCount = await schedulerSpy.clearCount()

        #expect(updatedBook.completionStatus.isCompleted == true)
        #expect(updatedBook.completionStatus.reviewAfterCompletion == review)
        #expect(updatedBook.userSettings.targetEndDate == completionDate)
        #expect(clearCount == 1)
    }

    @Test("BookCompletionUseCase.completeBook으로 시작일이 완독일보다 미래인 경우 처리")
    func testCompleteBookFutureStartDate() async throws {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let earlyCompletionDate = makeDate("2025-01-05")
        let useCase = makeBookCompletionUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: ReadingDateProviderStub(todayValue: earlyCompletionDate)
        )

        var testBook = createTestBook(totalPages: 300, isCompleted: false)
        testBook.userSettings = FGUserSetting(
            startPage: 1,
            targetEndPage: 300,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-31"),
            excludedReadingDays: []
        )
        await mockRepo.setBooks([testBook])

        try await useCase.completeBook(
            id: testBook.id,
            review: "빨리 읽었어요"
        )

        let updatedBook = try await mockRepo.fetchBook(by: testBook.id)
        #expect(updatedBook.userSettings.startDate == earlyCompletionDate)
        #expect(updatedBook.userSettings.targetEndDate == earlyCompletionDate)
    }

    @Test("BookCompletionUseCase.completeBook은 내부 todayProvider를 통해 완독일을 해상한다")
    func testCompleteBookUsesTodayProvider() async throws {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let todayProvider = ReadingDateProviderSpy(todayValue: makeDate("2025-01-20"))
        let useCase = makeBookCompletionUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: todayProvider
        )

        let testBook = createTestBook(totalPages: 300, isCompleted: false)
        await mockRepo.setBooks([testBook])

        try await useCase.completeBook(id: testBook.id, review: "리뷰")

        #expect(todayProvider.callCount == 1)
    }

    @Test("BookCompletionUseCase.completionCelebrationSummary는 todayProvider 기준으로 요약을 계산한다")
    func testCompletionCelebrationSummary() {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let today = makeDate("2025-01-20")
        let useCase = makeBookCompletionUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: ReadingDateProviderStub(todayValue: today)
        )

        var testBook = createTestBook(totalPages: 300, isCompleted: true)
        testBook.userSettings = FGUserSetting(
            startPage: 1,
            targetEndPage: 300,
            startDate: makeDate("2025-01-01"),
            targetEndDate: makeDate("2025-01-31"),
            excludedReadingDays: []
        )
        testBook.readingProgress = FGReadingProgress(
            dailyReadingRecords: [
                makeDate("2025-01-01").toYearMonthDayString(): ReadingRecord(targetPages: 10, pagesRead: 10),
                makeDate("2025-01-02").toYearMonthDayString(): ReadingRecord(targetPages: 10, pagesRead: 0),
                makeDate("2025-01-03").toYearMonthDayString(): ReadingRecord(targetPages: 10, pagesRead: 20)
            ],
            lastReadDate: nil,
            lastReadPage: 20
        )

        let summary = useCase.completionCelebrationSummary(for: testBook)

        #expect(summary.startDate == makeDate("2025-01-01"))
        #expect(summary.endDate == today)
        #expect(summary.totalReadingDays == 2)
        #expect(summary.pagesPerDay == 150)
    }

    @Test("BookCompletionUseCase.completionCelebrationSummary는 시작일이 오늘보다 늦으면 오늘로 보정한다")
    func testCompletionCelebrationSummaryClampsFutureStartDate() {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let today = makeDate("2025-01-20")
        let useCase = makeBookCompletionUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: ReadingDateProviderStub(todayValue: today)
        )

        var testBook = createTestBook(totalPages: 300, isCompleted: true)
        testBook.userSettings = FGUserSetting(
            startPage: 1,
            targetEndPage: 300,
            startDate: makeDate("2025-01-25"),
            targetEndDate: makeDate("2025-01-31"),
            excludedReadingDays: []
        )

        let summary = useCase.completionCelebrationSummary(for: testBook)

        #expect(summary.startDate == today)
        #expect(summary.endDate == today)
    }

    @Test("BookCompletionUseCase.updateCompletionReview로 완독 소감만 수정")
    func testUpdateCompletionReview() async throws {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let useCase = makeBookCompletionUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy
        )

        var testBook = createTestBook(totalPages: 300, isCompleted: true)
        testBook.completionStatus = FGCompletionStatus(
            isCompleted: true,
            reviewAfterCompletion: "기존 소감"
        )
        await mockRepo.setBooks([testBook])

        try await useCase.updateCompletionReview(id: testBook.id, review: "수정된 소감")

        let updatedBook = try await mockRepo.fetchBook(by: testBook.id)
        #expect(updatedBook.completionStatus.isCompleted == true)
        #expect(updatedBook.completionStatus.reviewAfterCompletion == "수정된 소감")
        #expect(updatedBook.userSettings.targetEndDate == testBook.userSettings.targetEndDate)
    }

    @Test("ReadingPlanUseCase.updateReadingPlan으로 목표기간/쉬는날 변경 시 설정과 진행률 갱신")
    func testUpdateReadingPlan() async throws {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let today = makeDate("2025-01-03")
        let useCase = makeReadingPlanUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: ReadingDateProviderStub(todayValue: today)
        )

        var testBook = createTestBook(totalPages: 300, isCompleted: false)
        testBook.readingProgress = FGReadingProgress(
            dailyReadingRecords: [
                makeDate("2025-01-01").toYearMonthDayString(): ReadingRecord(targetPages: 10, pagesRead: 10),
                makeDate("2025-01-02").toYearMonthDayString(): ReadingRecord(targetPages: 20, pagesRead: 20)
            ],
            lastReadDate: makeDate("2025-01-02"),
            lastReadPage: 20
        )
        await mockRepo.setBooks([testBook])

        let newStartDate = makeDate("2025-01-01")
        let newEndDate = makeDate("2025-02-10")
        let excludedDays = [makeDate("2025-01-05")]

        try await useCase.updateReadingPlan(
            bookId: testBook.id,
            startDate: newStartDate,
            targetEndDate: newEndDate,
            excludedReadingDays: excludedDays
        )

        let updatedBook = try await mockRepo.fetchBook(by: testBook.id)
        let setupCount = await schedulerSpy.setupCount()

        #expect(updatedBook.userSettings.startDate == newStartDate)
        #expect(updatedBook.userSettings.targetEndDate == newEndDate)
        #expect(updatedBook.userSettings.excludedReadingDays == excludedDays)
        #expect(updatedBook.readingProgress != testBook.readingProgress)
        #expect(setupCount == 1)
    }

    @Test("ReadingPlanUseCase는 내부 todayProvider 값을 사용해 계획 재계산 기준일을 해상한다")
    func testUpdateReadingPlanUsesTodayProvider() async throws {
        let mockRepo = MockBookRepo()
        let schedulerSpy = NotificationSchedulerSpy()
        let todayProvider = ReadingDateProviderSpy(todayValue: makeDate("2025-01-03"))
        let useCase = makeReadingPlanUseCase(
            repo: mockRepo,
            notificationScheduler: schedulerSpy,
            todayProvider: todayProvider
        )

        let testBook = createTestBook(totalPages: 300, isCompleted: false)
        await mockRepo.setBooks([testBook])

        try await useCase.updateReadingPlan(
            bookId: testBook.id,
            startDate: makeDate("2025-01-01"),
            targetEndDate: makeDate("2025-02-10"),
            excludedReadingDays: []
        )

        #expect(todayProvider.callCount == 1)
    }
}
