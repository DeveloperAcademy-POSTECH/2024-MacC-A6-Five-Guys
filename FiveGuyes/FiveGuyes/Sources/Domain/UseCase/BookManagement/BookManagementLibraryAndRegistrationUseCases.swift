//
//  BookManagementLibraryAndRegistrationUseCases.swift
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
    func setupNotifications(for readingBook: FGUserBook) async
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
    private let notificationScheduler: any ReadingNotificationScheduling
    private let todayProvider: any ReadingDateProviding

    init(
        fetchReadingBooksUseCase: FetchReadingBooksUseCase,
        fetchCompletedBooksUseCase: FetchCompletedBooksUseCase,
        deleteBookUseCase: DeleteBookUseCase,
        rescheduleOnAppOpenUseCase: RescheduleOnAppOpenUseCase,
        notificationScheduler: any ReadingNotificationScheduling,
        todayProvider: any ReadingDateProviding
    ) {
        self.fetchReadingBooksUseCase = fetchReadingBooksUseCase
        self.fetchCompletedBooksUseCase = fetchCompletedBooksUseCase
        self.deleteBookUseCase = deleteBookUseCase
        self.rescheduleOnAppOpenUseCase = rescheduleOnAppOpenUseCase
        self.notificationScheduler = notificationScheduler
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

    func setupNotifications(for readingBook: FGUserBook) async {
        await notificationScheduler.setupAllNotifications(readingBook)
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
