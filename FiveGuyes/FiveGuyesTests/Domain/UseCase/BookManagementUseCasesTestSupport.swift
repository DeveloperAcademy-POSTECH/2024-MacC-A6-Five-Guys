//
//  BookManagementUseCasesTestSupport.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("BookManagementUseCases 테스트")
struct BookManagementUseCasesTests {
    func createTestBook(
        id: UUID = UUID(),
        title: String = "테스트 책",
        author: String = "테스트 작가",
        totalPages: Int = 300,
        isCompleted: Bool = false
    ) -> FGUserBook {
        FGUserBook(
            id: id,
            bookMetaData: FGBookMetaData(
                title: title,
                author: author,
                coverImageURL: "https://example.com/cover.jpg",
                totalPages: totalPages
            ),
            userSettings: FGUserSetting(
                startPage: 1,
                targetEndPage: totalPages,
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

    func makeDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.app.timeZone
        guard let date = formatter.date(from: dateString) else {
            fatalError("Invalid date string: \(dateString)")
        }
        return date.onlyDate
    }

    func makeReadingLibraryUseCase(
        repo: BookRepo,
        notificationScheduler: any ReadingNotificationScheduling,
        todayProvider: any ReadingDateProviding = ReadingDateProviderStub(todayValue: .distantPast)
    ) -> ReadingLibraryUseCase {
        ReadingLibraryUseCase(
            fetchReadingBooksUseCase: FetchReadingBooksUseCase(repo: repo),
            fetchCompletedBooksUseCase: FetchCompletedBooksUseCase(repo: repo),
            deleteBookUseCase: DeleteBookUseCase(
                repo: repo,
                notificationScheduler: notificationScheduler
            ),
            rescheduleOnAppOpenUseCase: RescheduleOnAppOpenUseCase(
                repo: repo,
                scheduleCalculator: ReadingScheduleCalculator()
            ),
            todayProvider: todayProvider
        )
    }

    func makeDailyReadingUseCase(
        repo: BookRepo,
        notificationScheduler: any ReadingNotificationScheduling,
        todayProvider: any ReadingDateProviding = ReadingDateProviderStub(todayValue: .distantPast)
    ) -> DailyReadingUseCase {
        DailyReadingUseCase(
            recordReadingUseCase: RecordReadingUseCase(
                repo: repo,
                notificationScheduler: notificationScheduler,
                scheduleCalculator: ReadingScheduleCalculator()
            ),
            todayProvider: todayProvider
        )
    }

    func makeBookCompletionUseCase(
        repo: BookRepo,
        notificationScheduler: any ReadingNotificationScheduling,
        todayProvider: any ReadingDateProviding = ReadingDateProviderStub(todayValue: .distantPast)
    ) -> BookCompletionUseCase {
        BookCompletionUseCase(
            completeBookUseCase: CompleteBookUseCase(
                repo: repo,
                notificationScheduler: notificationScheduler
            ),
            updateCompletionReviewUseCase: UpdateCompletionReviewUseCase(repo: repo),
            todayProvider: todayProvider
        )
    }

    func makeReadingPlanUseCase(
        repo: BookRepo,
        notificationScheduler: any ReadingNotificationScheduling,
        todayProvider: any ReadingDateProviding = ReadingDateProviderStub(todayValue: .distantPast)
    ) -> ReadingPlanUseCase {
        ReadingPlanUseCase(
            updateReadingPlanUseCase: UpdateReadingPlanUseCase(
                repo: repo,
                notificationScheduler: notificationScheduler,
                scheduleCalculator: ReadingScheduleCalculator()
            ),
            todayProvider: todayProvider
        )
    }

    func makeBookRegistrationUseCase(
        repo: BookRepo,
        notificationScheduler: any ReadingNotificationScheduling
    ) -> BookRegistrationUseCase {
        BookRegistrationUseCase(
            registerBookUseCase: RegisterBookUseCase(
                repo: repo,
                notificationScheduler: notificationScheduler,
                scheduleCalculator: ReadingScheduleCalculator()
            )
        )
    }
}

actor NotificationSchedulerSpy: ReadingNotificationScheduling {
    private var setupBooks: [FGUserBook] = []
    private var clearRequestsCallCount = 0

    func setupAllNotifications(_ readingBook: FGUserBook) async {
        setupBooks.append(readingBook)
    }

    func clearRequests() async {
        clearRequestsCallCount += 1
    }

    func setupCount() -> Int {
        setupBooks.count
    }

    func lastSetupBook() -> FGUserBook? {
        setupBooks.last
    }

    func clearCount() -> Int {
        clearRequestsCallCount
    }
}

final class ReadingDateProviderSpy: ReadingDateProviding {
    var todayValue: Date
    private(set) var callCount = 0

    init(todayValue: Date) {
        self.todayValue = todayValue
    }

    func today() -> Date {
        callCount += 1
        return todayValue
    }
}

struct ReadingDateProviderStub: ReadingDateProviding {
    let todayValue: Date

    func today() -> Date {
        todayValue
    }
}
