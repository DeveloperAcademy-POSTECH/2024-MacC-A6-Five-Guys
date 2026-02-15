//
//  PreviewSupport.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

#if DEBUG
import Foundation
import SwiftData

@MainActor
enum PreviewSupport {
    static func makeDependencies() -> AppDependencies {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(
                for: UserBookSchemaV2.UserBookV2.self,
                configurations: config
            )
            return AppDependencies(modelContainer: container)
        } catch {
            fatalError("Preview ModelContainer 생성 실패: \(error)")
        }
    }

    static func makeCoordinator() -> NavigationCoordinator {
        NavigationCoordinator(appDependencies: makeDependencies())
    }
}

final class PreviewBookManagementService: BookManagementService {
    private var readingBooks: [FGUserBook]
    private var completedBooks: [FGUserBook]
    private let todayProvider: any ReadingDateProviding
    var previewRecordReadingResult: RecordReadingResult?

    init(
        readingBooks: [FGUserBook],
        completedBooks: [FGUserBook],
        todayProvider: any ReadingDateProviding = DefaultReadingDateProvider()
    ) {
        self.readingBooks = readingBooks
        self.completedBooks = completedBooks
        self.todayProvider = todayProvider
    }

    init(todayProvider: any ReadingDateProviding = DefaultReadingDateProvider()) {
        self.readingBooks = [
            PreviewBookFixtureFactory.makeBook(title: "읽는 중인 샘플 도서", isCompleted: false)
        ]
        self.completedBooks = [
            PreviewBookFixtureFactory.makeBook(title: "완독한 샘플 도서", isCompleted: true)
        ]
        self.todayProvider = todayProvider
    }

    func registerBook(_ input: RegisterBookInput) async throws -> FGUserBook {
        let newBook = FGUserBook(
            id: UUID(),
            bookMetaData: input.bookMetaData,
            userSettings: input.userSettings,
            readingProgress: FGReadingProgress(
                dailyReadingRecords: [:],
                lastReadDate: nil,
                lastReadPage: input.userSettings.startPage
            ),
            completionStatus: FGCompletionStatus(isCompleted: false, reviewAfterCompletion: "")
        )
        readingBooks.append(newBook)
        return newBook
    }

    func recordReading(bookId: UUID, pagesRead: Int) async throws -> RecordReadingResult {
        if let previewRecordReadingResult {
            return previewRecordReadingResult
        }
        let book = try await fetchBookDetail(id: bookId)
        return .recorded(updatedBook: book)
    }

    func deleteBook(id: UUID) async throws {
        readingBooks.removeAll { $0.id == id }
        completedBooks.removeAll { $0.id == id }
    }

    func completeBook(id: UUID, review: String) async throws {
        if let readingIndex = readingBooks.firstIndex(where: { $0.id == id }) {
            var book = readingBooks.remove(at: readingIndex)
            book.completionStatus = FGCompletionStatus(isCompleted: true, reviewAfterCompletion: review)
            completedBooks.append(book)
            return
        }

        if let completedIndex = completedBooks.firstIndex(where: { $0.id == id }) {
            completedBooks[completedIndex].completionStatus = FGCompletionStatus(
                isCompleted: true,
                reviewAfterCompletion: review
            )
            return
        }

        throw RepoError.notFound
    }

    func updateCompletionReview(id: UUID, review: String) async throws {
        if let readingIndex = readingBooks.firstIndex(where: { $0.id == id }) {
            readingBooks[readingIndex].completionStatus = FGCompletionStatus(
                isCompleted: readingBooks[readingIndex].completionStatus.isCompleted,
                reviewAfterCompletion: review
            )
            return
        }

        if let completedIndex = completedBooks.firstIndex(where: { $0.id == id }) {
            completedBooks[completedIndex].completionStatus = FGCompletionStatus(
                isCompleted: completedBooks[completedIndex].completionStatus.isCompleted,
                reviewAfterCompletion: review
            )
            return
        }

        throw RepoError.notFound
    }

    func updateReadingPlan(
        bookId: UUID,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date]
    ) async throws {
        guard let index = readingBooks.firstIndex(where: { $0.id == bookId }) else {
            throw RepoError.notFound
        }

        let currentSettings = readingBooks[index].userSettings
        readingBooks[index].userSettings = FGUserSetting(
            startPage: currentSettings.startPage,
            targetEndPage: currentSettings.targetEndPage,
            startDate: startDate,
            targetEndDate: targetEndDate,
            excludedReadingDays: excludedReadingDays
        )
    }

    func fetchReadingBooks() async throws -> [FGUserBook] {
        readingBooks
    }

    func fetchCompletedBooks() async throws -> [FGUserBook] {
        completedBooks
    }

    func fetchBookDetail(id: UUID) async throws -> FGUserBook {
        if let readingBook = readingBooks.first(where: { $0.id == id }) {
            return readingBook
        }

        if let completedBook = completedBooks.first(where: { $0.id == id }) {
            return completedBook
        }

        throw RepoError.notFound
    }

    func rescheduleOnAppOpen(bookId: UUID) async throws {
        guard readingBooks.contains(where: { $0.id == bookId }) else {
            throw RepoError.notFound
        }
    }

    func today() -> Date {
        todayProvider.today()
    }
}

@MainActor
final class PreviewNotificationManager: NotificationManaging {
    var isAuthorized = true

    func requestAuthorization() async -> Bool {
        isAuthorized
    }

    func clearRequests() async {}

    func setupAllNotifications(_ readingBook: FGUserBook) async {}

    func updateNotification(notificationType: NotificationType) async {}
}

struct PreviewReadingLibraryUseCaseAdapter: ReadingLibraryUsing {
    let service: any BookManagementService

    func fetchLibrarySnapshot() async throws -> ReadingLibrarySnapshot {
        let readingBooks = try await service.fetchReadingBooks()
        let completedBooks = try await service.fetchCompletedBooks()
        return ReadingLibrarySnapshot(readingBooks: readingBooks, completedBooks: completedBooks)
    }

    func deleteBook(id: UUID) async throws {
        try await service.deleteBook(id: id)
    }

    func rescheduleOnAppOpen(bookId: UUID) async throws {
        try await service.rescheduleOnAppOpen(bookId: bookId)
    }

    func setupNotifications(for readingBook: FGUserBook) async {
    }

    func today() -> Date {
        service.today()
    }
}

struct PreviewDailyReadingUseCaseAdapter: DailyReadingUsing {
    let service: any BookManagementService

    func recordReading(bookId: UUID, pagesRead: Int) async throws -> RecordReadingResult {
        try await service.recordReading(bookId: bookId, pagesRead: pagesRead)
    }

    func today() -> Date {
        service.today()
    }
}

struct PreviewBookCompletionUseCaseAdapter: BookCompletionUsing {
    let service: any BookManagementService

    func completeBook(id: UUID, review: String) async throws {
        try await service.completeBook(id: id, review: review)
    }

    func updateCompletionReview(id: UUID, review: String) async throws {
        try await service.updateCompletionReview(id: id, review: review)
    }

    func completionCelebrationSummary(for book: FGUserBook) -> CompletionCelebrationSummary {
        CompletionCelebrationSummary.make(for: book, endDate: service.today())
    }
}

struct PreviewReadingPlanUseCaseAdapter: ReadingPlanUsing {
    let service: any BookManagementService

    func updateReadingPlan(
        bookId: UUID,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date]
    ) async throws {
        try await service.updateReadingPlan(
            bookId: bookId,
            startDate: startDate,
            targetEndDate: targetEndDate,
            excludedReadingDays: excludedReadingDays
        )
    }

    func today() -> Date {
        service.today()
    }
}

struct PreviewBookRegistrationUseCaseAdapter: BookRegistrationUsing {
    let service: any BookManagementService

    func registerBook(_ input: RegisterBookInput) async throws -> FGUserBook {
        try await service.registerBook(input)
    }
}

final class PreviewNotificationSettingsStore: NotificationSettingsStoring {
    private var isDisabled: Bool
    private var reminderHour: Int
    private var reminderMinute: Int

    init(isDisabled: Bool = false, reminderHour: Int = 9, reminderMinute: Int = 0) {
        self.isDisabled = isDisabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }

    func saveNotificationDisabled(_ isNotificationDisabled: Bool) {
        isDisabled = isNotificationDisabled
    }

    func fetchNotificationDisabled() -> Bool {
        isDisabled
    }

    func saveNotificationTime(hour: Int, minute: Int) {
        reminderHour = hour
        reminderMinute = minute
    }

    func fetchNotificationReminderTime() -> (hour: Int, minute: Int) {
        (reminderHour, reminderMinute)
    }
}

#endif
