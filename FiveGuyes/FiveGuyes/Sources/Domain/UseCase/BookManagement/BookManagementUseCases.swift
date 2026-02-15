//
//  BookManagementUseCases.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-14.
//

import Foundation

struct ReadingLibrarySnapshot {
    let readingBooks: [FGUserBook]
    let completedBooks: [FGUserBook]
}

struct CompletionCelebrationSummary: Equatable {
    let startDate: Date
    let endDate: Date
    let totalReadingDays: Int
    let pagesPerDay: Int

    static func make(
        for book: FGUserBook,
        endDate: Date,
        pageMath: PageMathCalculator = PageMathCalculator()
    ) -> CompletionCelebrationSummary {
        let startDate = min(book.userSettings.startDate, endDate)

        let totalReadingDays = max(
            book.readingProgress.dailyReadingRecords.values.filter { $0.pagesRead > 0 }.count,
            1
        )

        let totalReadingPages = (try? pageMath.pagesBetween(
            from: book.userSettings.startPage,
            to: book.userSettings.targetEndPage
        )) ?? 0

        let pagesPerDay = (try? pageMath.pagesPerDay(
            totalPages: totalReadingPages,
            totalDays: totalReadingDays
        )) ?? totalReadingPages

        return CompletionCelebrationSummary(
            startDate: startDate,
            endDate: endDate,
            totalReadingDays: totalReadingDays,
            pagesPerDay: pagesPerDay
        )
    }
}

protocol ReadingLibraryUsing {
    func fetchLibrarySnapshot() async throws -> ReadingLibrarySnapshot
    func deleteBook(id: UUID) async throws
    func rescheduleOnAppOpen(bookId: UUID) async throws
    func today() -> Date
}

protocol DailyReadingUsing {
    func recordReading(bookId: UUID, pagesRead: Int) async throws -> RecordReadingResult
    func today() -> Date
}

protocol BookCompletionUsing {
    func completeBook(id: UUID, review: String) async throws
    func updateCompletionReview(id: UUID, review: String) async throws
    func completionCelebrationSummary(for book: FGUserBook) -> CompletionCelebrationSummary
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

protocol BookRegistrationUsing {
    func registerBook(_ input: RegisterBookInput) async throws -> FGUserBook
}

struct ReadingLibraryUseCase: ReadingLibraryUsing {
    private let fetchReadingBooksUseCase: FetchReadingBooksUseCase
    private let fetchCompletedBooksUseCase: FetchCompletedBooksUseCase
    private let deleteBookUseCase: DeleteBookUseCase
    private let rescheduleOnAppOpenUseCase: RescheduleOnAppOpenUseCase
    private let todayProvider: any ReadingDateProviding

    init(
        fetchReadingBooksUseCase: FetchReadingBooksUseCase,
        fetchCompletedBooksUseCase: FetchCompletedBooksUseCase,
        deleteBookUseCase: DeleteBookUseCase,
        rescheduleOnAppOpenUseCase: RescheduleOnAppOpenUseCase,
        todayProvider: any ReadingDateProviding
    ) {
        self.fetchReadingBooksUseCase = fetchReadingBooksUseCase
        self.fetchCompletedBooksUseCase = fetchCompletedBooksUseCase
        self.deleteBookUseCase = deleteBookUseCase
        self.rescheduleOnAppOpenUseCase = rescheduleOnAppOpenUseCase
        self.todayProvider = todayProvider
    }

    func fetchLibrarySnapshot() async throws -> ReadingLibrarySnapshot {
        let readingBooks = try await fetchReadingBooksUseCase.execute()
        let completedBooks = try await fetchCompletedBooksUseCase.execute()

        return ReadingLibrarySnapshot(
            readingBooks: readingBooks,
            completedBooks: completedBooks
        )
    }

    func deleteBook(id: UUID) async throws {
        try await deleteBookUseCase.execute(id: id)
    }

    func today() -> Date {
        todayProvider.today()
    }

    func rescheduleOnAppOpen(bookId: UUID) async throws {
        let today = todayProvider.today()
        try await rescheduleOnAppOpenUseCase.execute(bookId: bookId, today: today)
    }
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

    func today() -> Date {
        todayProvider.today()
    }

    func recordReading(bookId: UUID, pagesRead: Int) async throws -> RecordReadingResult {
        let readDate = todayProvider.today()
        return try await recordReadingUseCase.execute(
            bookId: bookId,
            pagesRead: pagesRead,
            readDate: readDate
        )
    }
}

struct BookCompletionUseCase: BookCompletionUsing {
    private let completeBookUseCase: CompleteBookUseCase
    private let updateCompletionReviewUseCase: UpdateCompletionReviewUseCase
    private let todayProvider: any ReadingDateProviding

    init(
        completeBookUseCase: CompleteBookUseCase,
        updateCompletionReviewUseCase: UpdateCompletionReviewUseCase,
        todayProvider: any ReadingDateProviding
    ) {
        self.completeBookUseCase = completeBookUseCase
        self.updateCompletionReviewUseCase = updateCompletionReviewUseCase
        self.todayProvider = todayProvider
    }

    func completeBook(id: UUID, review: String) async throws {
        let completionDate = todayProvider.today()
        try await completeBookUseCase.execute(
            id: id,
            completionDate: completionDate,
            review: review
        )
    }

    func updateCompletionReview(id: UUID, review: String) async throws {
        try await updateCompletionReviewUseCase.execute(id: id, review: review)
    }

    func completionCelebrationSummary(for book: FGUserBook) -> CompletionCelebrationSummary {
        CompletionCelebrationSummary.make(for: book, endDate: todayProvider.today())
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

    func today() -> Date {
        todayProvider.today()
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
}

struct BookRegistrationUseCase: BookRegistrationUsing {
    private let registerBookUseCase: RegisterBookUseCase

    init(registerBookUseCase: RegisterBookUseCase) {
        self.registerBookUseCase = registerBookUseCase
    }

    func registerBook(_ input: RegisterBookInput) async throws -> FGUserBook {
        try await registerBookUseCase.execute(input)
    }
}

struct FetchReadingBooksUseCase {
    let repository: BookRepository

    func execute() async throws -> [FGUserBook] {
        try await repository.getReadingBooks()
    }
}

struct FetchCompletedBooksUseCase {
    let repository: BookRepository

    func execute() async throws -> [FGUserBook] {
        try await repository.getCompletedBooks()
    }
}

struct FetchBookDetailUseCase {
    let repository: BookRepository

    func execute(id: UUID) async throws -> FGUserBook {
        try await repository.fetchBook(by: id)
    }
}

struct RescheduleOnAppOpenUseCase {
    let repository: BookRepository
    let scheduleCalculator: ReadingScheduleCalculator

    func execute(bookId: UUID, today: Date) async throws {
        let currentBook = try await repository.fetchBook(by: bookId)

        let updatedProgress = try scheduleCalculator.rescheduleOnAppOpen(
            settings: currentBook.userSettings,
            progress: currentBook.readingProgress,
            today: today
        )

        guard updatedProgress != currentBook.readingProgress else {
            return
        }

        let updatedBook = FGUserBook(
            id: currentBook.id,
            bookMetaData: currentBook.bookMetaData,
            userSettings: currentBook.userSettings,
            readingProgress: updatedProgress,
            completionStatus: currentBook.completionStatus
        )

        try await repository.updateBook(updatedBook)
    }
}

struct RegisterBookUseCase {
    let repository: BookRepository
    let notificationScheduler: any ReadingNotificationScheduling
    let scheduleCalculator: ReadingScheduleCalculator

    func execute(_ input: RegisterBookInput) async throws -> FGUserBook {
        let initialProgress = try scheduleCalculator.createInitialSchedule(settings: input.userSettings)

        let bookWithSchedule = FGUserBook(
            id: UUID(),
            bookMetaData: input.bookMetaData,
            userSettings: input.userSettings,
            readingProgress: initialProgress,
            completionStatus: FGCompletionStatus(isCompleted: false, reviewAfterCompletion: "")
        )

        try await repository.addBook(bookWithSchedule)
        await notificationScheduler.setupAllNotifications(bookWithSchedule)

        return bookWithSchedule
    }
}

struct RecordReadingUseCase {
    let repository: BookRepository
    let notificationScheduler: any ReadingNotificationScheduling
    let scheduleCalculator: ReadingScheduleCalculator

    func execute(bookId: UUID, pagesRead: Int, readDate: Date) async throws -> RecordReadingResult {
        let currentBook = try await repository.fetchBook(by: bookId)

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

        try await repository.updateBook(updatedBook)
        await notificationScheduler.setupAllNotifications(updatedBook)

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

        try await repository.updateBook(updatedBook)
        await notificationScheduler.setupAllNotifications(updatedBook)
    }
}

struct DeleteBookUseCase {
    let repository: BookRepository
    let notificationScheduler: any ReadingNotificationScheduling

    func execute(id: UUID) async throws {
        try await repository.deleteBook(by: id)

        let remainingReadingBooks = try await repository.getReadingBooks()
        if let nextReadingBook = remainingReadingBooks.first {
            await notificationScheduler.setupAllNotifications(nextReadingBook)
        } else {
            await notificationScheduler.clearRequests()
        }
    }
}

struct CompleteBookUseCase {
    let repository: BookRepository
    let notificationScheduler: any ReadingNotificationScheduling

    func execute(id: UUID, completionDate: Date, review: String) async throws {
        let currentBook = try await repository.fetchBook(by: id)

        let updatedStatus = FGCompletionStatus(
            isCompleted: true,
            reviewAfterCompletion: review
        )

        let updatedSettings: FGUserSetting
        if currentBook.userSettings.startDate > completionDate {
            updatedSettings = FGUserSetting(
                startPage: currentBook.userSettings.startPage,
                targetEndPage: currentBook.userSettings.targetEndPage,
                startDate: completionDate,
                targetEndDate: completionDate,
                excludedReadingDays: currentBook.userSettings.excludedReadingDays
            )
        } else {
            updatedSettings = FGUserSetting(
                startPage: currentBook.userSettings.startPage,
                targetEndPage: currentBook.userSettings.targetEndPage,
                startDate: currentBook.userSettings.startDate,
                targetEndDate: completionDate,
                excludedReadingDays: currentBook.userSettings.excludedReadingDays
            )
        }

        try await repository.updateCompletionStatus(bookId: id, status: updatedStatus)
        try await repository.updateSettings(bookId: id, settings: updatedSettings)
        await notificationScheduler.clearRequests()
    }
}

struct UpdateCompletionReviewUseCase {
    let repository: BookRepository

    func execute(id: UUID, review: String) async throws {
        let currentBook = try await repository.fetchBook(by: id)

        let updatedStatus = FGCompletionStatus(
            isCompleted: currentBook.completionStatus.isCompleted,
            reviewAfterCompletion: review
        )

        try await repository.updateCompletionStatus(bookId: id, status: updatedStatus)
    }
}

struct UpdateReadingPlanUseCase {
    let repository: BookRepository
    let notificationScheduler: any ReadingNotificationScheduling
    let scheduleCalculator: ReadingScheduleCalculator

    func execute(
        bookId: UUID,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date],
        today: Date
    ) async throws {
        let currentBook = try await repository.fetchBook(by: bookId)

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

        try await repository.updateBook(updatedBook)
        await notificationScheduler.setupAllNotifications(updatedBook)
    }
}
