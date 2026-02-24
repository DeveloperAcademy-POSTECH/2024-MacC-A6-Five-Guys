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

    static func bindReadingBook(_ book: FGUserBook) -> PreviewBookUseCaseBinding {
        PreviewBookUseCaseBinding(
            userBook: book,
            useCase: PreviewBookUseCaseStub(
                readingBooks: [book],
                completedBooks: []
            )
        )
    }

    static func bindCompletedBook(_ book: FGUserBook) -> PreviewBookUseCaseBinding {
        PreviewBookUseCaseBinding(
            userBook: book,
            useCase: PreviewBookUseCaseStub(
                readingBooks: [],
                completedBooks: [book]
            )
        )
    }
}

struct PreviewBookUseCaseBinding {
    let userBook: FGUserBook
    let useCase: PreviewBookUseCaseStub
}

private final class PreviewBookStore {
    var readingBooks: [FGUserBook]
    var completedBooks: [FGUserBook]

    init(readingBooks: [FGUserBook], completedBooks: [FGUserBook]) {
        self.readingBooks = readingBooks
        self.completedBooks = completedBooks
    }

    func fetchBookDetail(id: UUID) throws -> FGUserBook {
        if let readingBook = readingBooks.first(where: { $0.id == id }) {
            return readingBook
        }

        if let completedBook = completedBooks.first(where: { $0.id == id }) {
            return completedBook
        }

        throw RepoError.notFound
    }
}

final class PreviewBookUseCaseStub: ReadingLibraryUsing,
    HomeNotificationUsing,
    DailyReadingUsing,
    BookCompletionUsing,
    ReadingPlanUsing,
    BookRegistrationUsing {
    private let store: PreviewBookStore
    private let todayProvider: any ReadingDateProviding
    var previewRecordReadingResult: RecordReadingResult?

    // ID 기반 프리뷰에서는 bindReadingBook/bindCompletedBook 헬퍼를 사용해
    // 화면 book.id와 stub 저장소 데이터를 같은 인스턴스로 맞춘다.
    init(
        readingBooks: [FGUserBook] = [PreviewBookFixtureFactory.makeBook(title: "읽는 중인 샘플 도서", isCompleted: false)],
        completedBooks: [FGUserBook] = [PreviewBookFixtureFactory.makeBook(title: "완독한 샘플 도서", isCompleted: true)],
        previewRecordReadingResult: RecordReadingResult? = nil,
        todayProvider: any ReadingDateProviding = DefaultReadingDateProvider()
    ) {
        self.store = PreviewBookStore(readingBooks: readingBooks, completedBooks: completedBooks)
        self.previewRecordReadingResult = previewRecordReadingResult
        self.todayProvider = todayProvider
    }

    func fetchLibrarySnapshot() async throws -> ReadingLibrarySnapshot {
        ReadingLibrarySnapshot(readingBooks: store.readingBooks, completedBooks: store.completedBooks)
    }

    func deleteBook(id: UUID) async throws {
        store.readingBooks.removeAll { $0.id == id }
        store.completedBooks.removeAll { $0.id == id }
    }

    func rescheduleOnAppOpen(bookId: UUID) async throws {
        guard store.readingBooks.contains(where: { $0.id == bookId }) else {
            throw RepoError.notFound
        }
    }

    func setupNotifications(for readingBook: FGUserBook) async {
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
        store.readingBooks.append(newBook)
        return newBook
    }

    func recordReading(bookId: UUID, pagesRead: Int) async throws -> RecordReadingResult {
        if let previewRecordReadingResult {
            return previewRecordReadingResult
        }

        let book = try store.fetchBookDetail(id: bookId)
        return .recorded(updatedBook: book)
    }

    func completeBook(id: UUID, review: String) async throws {
        if let readingIndex = store.readingBooks.firstIndex(where: { $0.id == id }) {
            var book = store.readingBooks.remove(at: readingIndex)
            book.completionStatus = FGCompletionStatus(isCompleted: true, reviewAfterCompletion: review)
            store.completedBooks.append(book)
            return
        }

        if let completedIndex = store.completedBooks.firstIndex(where: { $0.id == id }) {
            store.completedBooks[completedIndex].completionStatus = FGCompletionStatus(
                isCompleted: true,
                reviewAfterCompletion: review
            )
            return
        }

        throw RepoError.notFound
    }

    func updateCompletionReview(id: UUID, review: String) async throws {
        if let readingIndex = store.readingBooks.firstIndex(where: { $0.id == id }) {
            store.readingBooks[readingIndex].completionStatus = FGCompletionStatus(
                isCompleted: store.readingBooks[readingIndex].completionStatus.isCompleted,
                reviewAfterCompletion: review
            )
            return
        }

        if let completedIndex = store.completedBooks.firstIndex(where: { $0.id == id }) {
            store.completedBooks[completedIndex].completionStatus = FGCompletionStatus(
                isCompleted: store.completedBooks[completedIndex].completionStatus.isCompleted,
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
        guard let index = store.readingBooks.firstIndex(where: { $0.id == bookId }) else {
            throw RepoError.notFound
        }

        let currentSettings = store.readingBooks[index].userSettings
        store.readingBooks[index].userSettings = FGUserSetting(
            startPage: currentSettings.startPage,
            targetEndPage: currentSettings.targetEndPage,
            startDate: startDate,
            targetEndDate: targetEndDate,
            excludedReadingDays: excludedReadingDays
        )
    }

    func completionCelebrationSummary(for book: FGUserBook) -> CompletionCelebrationSummary {
        CompletionCelebrationSummary.make(for: book, endDate: todayProvider.today())
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

    func updateMorningNotification(for readingBook: FGUserBook) async {}
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
