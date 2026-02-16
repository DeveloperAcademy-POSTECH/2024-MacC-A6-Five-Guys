//
//  DailyAndPlanUseCases.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-16.
//

import Foundation

protocol DailyReadingUsing {
    func recordReading(bookId: UUID, pagesRead: Int) async throws -> RecordReadingResult
    func today() -> Date
}

protocol ReadingPlanUsing {
    func updateReadingPlan(
        bookId: UUID,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date]
    ) async throws
    func today() -> Date
}

struct DailyReadingUseCase: DailyReadingUsing {
    private let recordReadingUseCase: RecordReadingUseCase
    private let todayProvider: any ReadingDateProviding

    init(
        recordReadingUseCase: RecordReadingUseCase,
        todayProvider: any ReadingDateProviding
    ) {
        self.recordReadingUseCase = recordReadingUseCase
        self.todayProvider = todayProvider
    }

    func recordReading(bookId: UUID, pagesRead: Int) async throws -> RecordReadingResult {
        let readDate = todayProvider.today()
        return try await recordReadingUseCase.execute(
            bookId: bookId,
            pagesRead: pagesRead,
            readDate: readDate
        )
    }

    func today() -> Date {
        todayProvider.today()
    }
}

struct ReadingPlanUseCase: ReadingPlanUsing {
    private let updateReadingPlanUseCase: UpdateReadingPlanUseCase
    private let todayProvider: any ReadingDateProviding

    init(
        updateReadingPlanUseCase: UpdateReadingPlanUseCase,
        todayProvider: any ReadingDateProviding
    ) {
        self.updateReadingPlanUseCase = updateReadingPlanUseCase
        self.todayProvider = todayProvider
    }

    func updateReadingPlan(
        bookId: UUID,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date]
    ) async throws {
        let today = todayProvider.today()
        try await updateReadingPlanUseCase.execute(
            bookId: bookId,
            startDate: startDate,
            targetEndDate: targetEndDate,
            excludedReadingDays: excludedReadingDays,
            today: today
        )
    }

    func today() -> Date {
        todayProvider.today()
    }
}

struct RecordReadingUseCase {
    let repo: BookRepo
    let notificationScheduler: any ReadingNotificationScheduling
    let scheduleCalculator: ReadingScheduleCalculator

    func execute(bookId: UUID, pagesRead: Int, readDate: Date) async throws -> RecordReadingResult {
        let currentBook = try await repo.fetchBook(by: bookId)

        if pagesRead > currentBook.userSettings.targetEndPage {
            return .exceedsTarget(currentTarget: currentBook.userSettings.targetEndPage)
        }

        let isTodayCompletionDate = Calendar.app.isDate(
            readDate,
            inSameDayAs: currentBook.userSettings.targetEndDate
        )

        if isTodayCompletionDate && pagesRead < currentBook.userSettings.targetEndPage {
            try await handleDateExtension(
                book: currentBook,
                pagesRead: pagesRead,
                readDate: readDate
            )
            return .dateExtended
        }

        let result = try scheduleCalculator.applyTodayReading(
            settings: currentBook.userSettings,
            progress: currentBook.readingProgress,
            pagesRead: pagesRead,
            date: readDate
        )

        let finalSettings = result.updatedSettings ?? currentBook.userSettings

        let updatedBook = FGUserBook(
            id: currentBook.id,
            bookMetaData: currentBook.bookMetaData,
            userSettings: finalSettings,
            readingProgress: result.progress,
            completionStatus: currentBook.completionStatus
        )

        try await persistUpdatedBookAndRefreshNotifications(
            updatedBook,
            repo: repo,
            notificationScheduler: notificationScheduler
        )

        if pagesRead >= currentBook.userSettings.targetEndPage {
            return .completed(updatedBook: updatedBook)
        }

        return .recorded(updatedBook: updatedBook)
    }

    private func handleDateExtension(
        book: FGUserBook,
        pagesRead: Int,
        readDate: Date
    ) async throws {
        let extendedSettings = FGUserSetting(
            startPage: book.userSettings.startPage,
            targetEndPage: book.userSettings.targetEndPage,
            startDate: book.userSettings.startDate,
            targetEndDate: book.userSettings.targetEndDate.addDays(1),
            excludedReadingDays: book.userSettings.excludedReadingDays
        )

        let result = try scheduleCalculator.applyTodayReading(
            settings: extendedSettings,
            progress: book.readingProgress,
            pagesRead: pagesRead,
            date: readDate
        )

        let finalSettings = result.updatedSettings ?? extendedSettings

        let updatedBook = FGUserBook(
            id: book.id,
            bookMetaData: book.bookMetaData,
            userSettings: finalSettings,
            readingProgress: result.progress,
            completionStatus: book.completionStatus
        )

        try await persistUpdatedBookAndRefreshNotifications(
            updatedBook,
            repo: repo,
            notificationScheduler: notificationScheduler
        )
    }
}

struct UpdateReadingPlanUseCase {
    let repo: BookRepo
    let notificationScheduler: any ReadingNotificationScheduling
    let scheduleCalculator: ReadingScheduleCalculator

    func execute(
        bookId: UUID,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date],
        today: Date
    ) async throws {
        let currentBook = try await repo.fetchBook(by: bookId)

        let newSettings = FGUserSetting(
            startPage: currentBook.userSettings.startPage,
            targetEndPage: currentBook.userSettings.targetEndPage,
            startDate: startDate,
            targetEndDate: targetEndDate,
            excludedReadingDays: excludedReadingDays
        )

        let updatedProgress = try scheduleCalculator.rescheduleForSettingsChange(
            newSettings: newSettings,
            progress: currentBook.readingProgress,
            today: today
        )

        let updatedBook = FGUserBook(
            id: currentBook.id,
            bookMetaData: currentBook.bookMetaData,
            userSettings: newSettings,
            readingProgress: updatedProgress,
            completionStatus: currentBook.completionStatus
        )

        try await persistUpdatedBookAndRefreshNotifications(
            updatedBook,
            repo: repo,
            notificationScheduler: notificationScheduler
        )
    }
}

private func persistUpdatedBookAndRefreshNotifications(
    _ updatedBook: FGUserBook,
    repo: BookRepo,
    notificationScheduler: any ReadingNotificationScheduling
) async throws {
    try await repo.updateBook(updatedBook)
    await notificationScheduler.setupAllNotifications(updatedBook)
}
