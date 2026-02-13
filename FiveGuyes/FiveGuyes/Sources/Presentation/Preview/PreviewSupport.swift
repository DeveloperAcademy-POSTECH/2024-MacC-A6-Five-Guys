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
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(
                for: UserBookSchemaV2.UserBookV2.self,
                configurations: configuration
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

@MainActor
final class PreviewBookManagementService: BookManagementService {
    private var readingBooks: [FGUserBook]
    private var completedBooks: [FGUserBook]
    var previewRecordReadingResult: RecordReadingResult?

    init(readingBooks: [FGUserBook], completedBooks: [FGUserBook]) {
        self.readingBooks = readingBooks
        self.completedBooks = completedBooks
    }

    init() {
        self.readingBooks = [PreviewSupport.sampleReadingBook]
        self.completedBooks = [PreviewSupport.sampleCompletedBook]
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

    func recordReading(bookId: UUID, pagesRead: Int, readDate: Date) async throws -> RecordReadingResult {
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

    func completeBook(id: UUID, completionDate: Date, review: String) async throws {
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

        throw RepositoryError.notFound
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

        throw RepositoryError.notFound
    }

    func updateReadingPlan(
        bookId: UUID,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date],
        today: Date
    ) async throws {
        guard let index = readingBooks.firstIndex(where: { $0.id == bookId }) else {
            throw RepositoryError.notFound
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

        throw RepositoryError.notFound
    }

    func rescheduleOnAppOpen(bookId: UUID, today: Date) async throws {
        guard readingBooks.contains(where: { $0.id == bookId }) else {
            throw RepositoryError.notFound
        }
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
