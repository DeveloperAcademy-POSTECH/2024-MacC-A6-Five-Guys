//
//  LibraryAndRegistrationUseCases.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-16.
//

import Foundation

struct ReadingLibrarySnapshot {
    let readingBooks: [FGUserBook]
    let completedBooks: [FGUserBook]
}

protocol ReadingLibraryUsing {
    func fetchLibrarySnapshot() async throws -> ReadingLibrarySnapshot
    func deleteBook(id: UUID) async throws
    func rescheduleOnAppOpen(bookId: UUID) async throws
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

    func rescheduleOnAppOpen(bookId: UUID) async throws {
        let today = todayProvider.today()
        try await rescheduleOnAppOpenUseCase.execute(bookId: bookId, today: today)
    }

    func today() -> Date {
        todayProvider.today()
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
    let repo: BookRepo

    func execute() async throws -> [FGUserBook] {
        try await repo.getReadingBooks()
    }
}

struct FetchCompletedBooksUseCase {
    let repo: BookRepo

    func execute() async throws -> [FGUserBook] {
        try await repo.getCompletedBooks()
    }
}

struct FetchBookDetailUseCase {
    let repo: BookRepo

    func execute(id: UUID) async throws -> FGUserBook {
        try await repo.fetchBook(by: id)
    }
}

struct RescheduleOnAppOpenUseCase {
    let repo: BookRepo
    let scheduleCalculator: ReadingScheduleCalculator

    func execute(bookId: UUID, today: Date) async throws {
        let currentBook = try await repo.fetchBook(by: bookId)

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

        try await repo.updateBook(updatedBook)
    }
}

struct RegisterBookUseCase {
    let repo: BookRepo
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

        try await repo.addBook(bookWithSchedule)
        await notificationScheduler.setupAllNotifications(bookWithSchedule)

        return bookWithSchedule
    }
}

struct DeleteBookUseCase {
    let repo: BookRepo
    let notificationScheduler: any ReadingNotificationScheduling

    func execute(id: UUID) async throws {
        try await repo.deleteBook(by: id)

        let remainingReadingBooks = try await repo.getReadingBooks()
        if let nextReadingBook = remainingReadingBooks.first {
            await notificationScheduler.setupAllNotifications(nextReadingBook)
        } else {
            await notificationScheduler.clearRequests()
        }
    }
}
