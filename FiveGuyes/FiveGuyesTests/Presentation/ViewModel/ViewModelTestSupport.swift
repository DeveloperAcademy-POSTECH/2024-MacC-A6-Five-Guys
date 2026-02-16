//
//  ViewModelTestSupport.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@MainActor
func makeBook(id: UUID = UUID(), isCompleted: Bool = false) -> FGUserBook {
    FGUserBook(
        id: id,
        bookMetaData: FGBookMetaData(
            title: "테스트 책",
            author: "테스트 작가",
            coverImageURL: nil,
            totalPages: 300
        ),
        userSettings: FGUserSetting(
            startPage: 1,
            targetEndPage: 300,
            startDate: makeDate("2025-01-01"),
            targetEndDate: makeDate("2025-01-31"),
            excludedReadingDays: []
        ),
        readingProgress: FGReadingProgress(
            dailyReadingRecords: [:],
            lastReadDate: nil,
            lastReadPage: 0
        ),
        completionStatus: FGCompletionStatus(
            isCompleted: isCompleted,
            reviewAfterCompletion: ""
        )
    )
}

@MainActor
func makeBookSearchItem(title: String) -> BookSearchItem {
    BookSearchItem(
        title: title,
        author: "테스트 저자",
        cover: nil,
        publisher: "테스트 출판사",
        isbn13: "9781234567890",
        pubDate: "20250101"
    )
}

@MainActor
func makeDate(_ dateString: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = Calendar.app.timeZone
    guard let date = formatter.date(from: dateString) else {
        fatalError("Invalid date string: \(dateString)")
    }
    return date.onlyDate
}

@MainActor
func waitUntil(
    timeoutNanoseconds: UInt64 = 500_000_000,
    pollIntervalNanoseconds: UInt64 = 5_000_000,
    condition: @escaping () -> Bool
) async -> Bool {
    let start = DispatchTime.now().uptimeNanoseconds
    while !condition() {
        if DispatchTime.now().uptimeNanoseconds - start >= timeoutNanoseconds {
            return false
        }
        await Task.yield()
        try? await Task.sleep(nanoseconds: pollIntervalNanoseconds)
    }
    return true
}

actor AsyncSignal {
    private var isSignaled = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func signal() {
        guard !isSignaled else { return }
        isSignaled = true
        let continuations = waiters
        waiters.removeAll()
        continuations.forEach { $0.resume() }
    }

    func wait() async {
        if isSignaled { return }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
}

actor AsyncGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func open() {
        guard !isOpen else { return }
        isOpen = true
        let continuations = waiters
        waiters.removeAll()
        continuations.forEach { $0.resume() }
    }
}

enum TestError: Error {
    case forced
}

final class ReadingLibraryUseCaseStub: ReadingLibraryUsing {
    var fetchReadingBooksResult: [FGUserBook]
    var fetchCompletedBooksResult: [FGUserBook]
    var fetchLibrarySnapshotError: Error?
    var deleteBookError: Error?
    var rescheduleOnAppOpenError: Error?
    var todayValue: Date = .distantPast
    var notificationService: (any NotificationManaging)?

    var fetchLibrarySnapshotCallCount = 0
    var deleteBookCallCount = 0
    var rescheduleOnAppOpenCallCount = 0

    init(
        readingBooks: [FGUserBook] = [.dummy],
        completedBooks: [FGUserBook] = [],
        notificationService: (any NotificationManaging)? = nil
    ) {
        self.fetchReadingBooksResult = readingBooks
        self.fetchCompletedBooksResult = completedBooks
        self.notificationService = notificationService
    }

    func fetchLibrarySnapshot() async throws -> ReadingLibrarySnapshot {
        fetchLibrarySnapshotCallCount += 1
        if let fetchLibrarySnapshotError { throw fetchLibrarySnapshotError }
        return ReadingLibrarySnapshot(
            readingBooks: fetchReadingBooksResult,
            completedBooks: fetchCompletedBooksResult
        )
    }

    func deleteBook(id: UUID) async throws {
        deleteBookCallCount += 1
        if let deleteBookError { throw deleteBookError }
        fetchReadingBooksResult.removeAll { $0.id == id }
        fetchCompletedBooksResult.removeAll { $0.id == id }
    }

    func rescheduleOnAppOpen(bookId: UUID) async throws {
        rescheduleOnAppOpenCallCount += 1
        if let rescheduleOnAppOpenError { throw rescheduleOnAppOpenError }
    }

    func setupNotifications(for readingBook: FGUserBook) async {
        await notificationService?.setupAllNotifications(readingBook)
    }

    func today() -> Date {
        todayValue
    }
}

final class DailyReadingUseCaseStub: DailyReadingUsing {
    var recordReadingResult: RecordReadingResult
    var recordReadingError: Error?
    var recordReadingDelayNanoseconds: UInt64 = 0
    var recordReadingGate: AsyncGate?
    var onRecordReadingStart: (() async -> Void)?
    var todayValue: Date = .distantPast

    var recordReadingCallCount = 0

    init(book: FGUserBook = .dummy) {
        self.recordReadingResult = .recorded(updatedBook: book)
    }

    func recordReading(bookId: UUID, pagesRead: Int) async throws -> RecordReadingResult {
        recordReadingCallCount += 1
        if let onRecordReadingStart {
            await onRecordReadingStart()
        }
        if let recordReadingGate {
            await recordReadingGate.wait()
        }
        if recordReadingDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: recordReadingDelayNanoseconds)
        }
        if let recordReadingError { throw recordReadingError }
        return recordReadingResult
    }

    func today() -> Date {
        todayValue
    }
}

final class BookCompletionUseCaseStub: BookCompletionUsing {
    var completeBookError: Error?
    var updateCompletionReviewError: Error?
    var completeBookDelayNanoseconds: UInt64 = 0
    var updateCompletionReviewDelayNanoseconds: UInt64 = 0
    var completeBookGate: AsyncGate?
    var onCompleteBookStart: (() async -> Void)?
    var todayValue: Date = .distantPast

    var completeBookCallCount = 0
    var updateCompletionReviewCallCount = 0

    func completeBook(id: UUID, review: String) async throws {
        completeBookCallCount += 1
        if let onCompleteBookStart {
            await onCompleteBookStart()
        }
        if let completeBookGate {
            await completeBookGate.wait()
        }
        if completeBookDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: completeBookDelayNanoseconds)
        }
        if let completeBookError { throw completeBookError }
    }

    func updateCompletionReview(id: UUID, review: String) async throws {
        updateCompletionReviewCallCount += 1
        if updateCompletionReviewDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: updateCompletionReviewDelayNanoseconds)
        }
        if let updateCompletionReviewError { throw updateCompletionReviewError }
    }

    func completionCelebrationSummary(for book: FGUserBook) -> CompletionCelebrationSummary {
        CompletionCelebrationSummary.make(for: book, endDate: todayValue)
    }
}

final class ReadingPlanUseCaseStub: ReadingPlanUsing {
    var updateReadingPlanError: Error?
    var updateReadingPlanDelayNanoseconds: UInt64 = 0
    var updateReadingPlanCallCount = 0
    var todayValue: Date = .distantPast

    func updateReadingPlan(
        bookId: UUID,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date]
    ) async throws {
        updateReadingPlanCallCount += 1
        if updateReadingPlanDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: updateReadingPlanDelayNanoseconds)
        }
        if let updateReadingPlanError { throw updateReadingPlanError }
    }

    func today() -> Date {
        todayValue
    }
}

final class BookRegistrationUseCaseStub: BookRegistrationUsing {
    var registerBookResult: FGUserBook
    var registerBookError: Error?
    var registerBookDelayNanoseconds: UInt64 = 0
    var registerBookCallCount = 0

    init(book: FGUserBook = .dummy) {
        self.registerBookResult = book
    }

    func registerBook(_ input: RegisterBookInput) async throws -> FGUserBook {
        registerBookCallCount += 1
        if registerBookDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: registerBookDelayNanoseconds)
        }
        if let registerBookError { throw registerBookError }
        return registerBookResult
    }
}

final class NotificationManagerStub: NotificationManaging {
    var isAuthorized = true
    var requestAuthorizationCallCount = 0
    var clearRequestsCallCount = 0
    var setupAllNotificationsCallCount = 0
    var setupAllNotificationsBookIDs: [UUID] = []
    var updateNotificationCallCount = 0
    var updateNotificationDelayNanoseconds: UInt64 = 0
    var ignoreCancelledCalls = false

    func requestAuthorization() async -> Bool {
        requestAuthorizationCallCount += 1
        return isAuthorized
    }

    func clearRequests() async {
        clearRequestsCallCount += 1
    }

    func setupAllNotifications(_ readingBook: FGUserBook) async {
        setupAllNotificationsCallCount += 1
        setupAllNotificationsBookIDs.append(readingBook.id)
    }

    func updateNotification(notificationType: NotificationType) async {
        if updateNotificationDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: updateNotificationDelayNanoseconds)
        }
        if ignoreCancelledCalls && Task.isCancelled {
            return
        }
        updateNotificationCallCount += 1
    }
}

final class NotificationSettingsStoreStub: NotificationSettingsStoring {
    private let storedDisabled: Bool
    private let storedReminderHour: Int
    private let storedReminderMinute: Int

    var savedNotificationDisabled: Bool?
    var savedReminderHour: Int?
    var savedReminderMinute: Int?

    init(disabled: Bool, reminderHour: Int, reminderMinute: Int) {
        self.storedDisabled = disabled
        self.storedReminderHour = reminderHour
        self.storedReminderMinute = reminderMinute
    }

    func saveNotificationDisabled(_ isNotificationDisabled: Bool) {
        savedNotificationDisabled = isNotificationDisabled
    }

    func fetchNotificationDisabled() -> Bool {
        storedDisabled
    }

    func saveNotificationTime(hour: Int, minute: Int) {
        savedReminderHour = hour
        savedReminderMinute = minute
    }

    func fetchNotificationReminderTime() -> (hour: Int, minute: Int) {
        (storedReminderHour, storedReminderMinute)
    }
}

final class BookSearchProviderStub: BookSearchProviding {
    var fetchBooksResult: [BookSearchItem] = []
    var fetchBookTotalPagesResult: Int = 0

    var fetchBooksError: Error?
    var fetchBookTotalPagesError: Error?

    var fetchBooksQueries: [String] = []
    var fetchTotalPagesISBNs: [String] = []

    func fetchBooks(query: String) async throws -> [BookSearchItem] {
        fetchBooksQueries.append(query)
        if let fetchBooksError { throw fetchBooksError }
        return fetchBooksResult
    }

    func fetchBookTotalPages(isbn: String) async throws -> Int {
        fetchTotalPagesISBNs.append(isbn)
        if let fetchBookTotalPagesError { throw fetchBookTotalPagesError }
        return fetchBookTotalPagesResult
    }
}
