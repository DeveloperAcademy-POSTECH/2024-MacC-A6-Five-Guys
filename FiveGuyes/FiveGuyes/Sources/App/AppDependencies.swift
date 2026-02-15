//
//  AppDependencies.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/12/26.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AppDependencies {
    private static let defaultBundleIdentifier = "com.zaehorang.FiveGuyes"
    private static let migrationStoreScope = "mainStore"

    let readingLibraryUseCase: any ReadingLibraryUsing
    let dailyReadingUseCase: any DailyReadingUsing
    let bookCompletionUseCase: any BookCompletionUsing
    let readingPlanUseCase: any ReadingPlanUsing
    let bookRegistrationUseCase: any BookRegistrationUsing
    let notificationService: any NotificationManaging
    let notificationSettingsStore: any NotificationSettingsStoring
    let bookSearchUseCase: any BookSearchUsing

    init(modelContainer: ModelContainer) {
        let migrationCompletionKey = Self.makeMigrationCompletionKey()
        let repository = SwiftDataBookRepository(
            modelContainer: modelContainer,
            migrationUserDefaults: .standard,
            migrationCompletionKey: migrationCompletionKey
        )

        do {
            try repository.prewarmReadingRecordKeyMigrationIfNeeded()
        } catch {
            // 앱 시작을 막지 않기 위해 prewarm 실패는 무시하고 fetch 경계 재시도에 맡깁니다.
        }

        let readingDateProvider = DefaultReadingDateProvider()
        let notificationService = NotificationManager(todayProvider: readingDateProvider)
        let scheduleCalculator = ReadingScheduleCalculator()

        let fetchReadingBooksUseCase = FetchReadingBooksUseCase(repository: repository)
        let fetchCompletedBooksUseCase = FetchCompletedBooksUseCase(repository: repository)
        let deleteBookUseCase = DeleteBookUseCase(
            repository: repository,
            notificationScheduler: notificationService
        )
        let rescheduleOnAppOpenUseCase = RescheduleOnAppOpenUseCase(
            repository: repository,
            scheduleCalculator: scheduleCalculator
        )
        let registerBookUseCase = RegisterBookUseCase(
            repository: repository,
            notificationScheduler: notificationService,
            scheduleCalculator: scheduleCalculator
        )
        let recordReadingUseCase = RecordReadingUseCase(
            repository: repository,
            notificationScheduler: notificationService,
            scheduleCalculator: scheduleCalculator
        )
        let completeBookUseCase = CompleteBookUseCase(
            repository: repository,
            notificationScheduler: notificationService
        )
        let updateCompletionReviewUseCase = UpdateCompletionReviewUseCase(repository: repository)
        let updateReadingPlanUseCase = UpdateReadingPlanUseCase(
            repository: repository,
            notificationScheduler: notificationService,
            scheduleCalculator: scheduleCalculator
        )

        self.readingLibraryUseCase = ReadingLibraryUseCase(
            fetchReadingBooksUseCase: fetchReadingBooksUseCase,
            fetchCompletedBooksUseCase: fetchCompletedBooksUseCase,
            deleteBookUseCase: deleteBookUseCase,
            rescheduleOnAppOpenUseCase: rescheduleOnAppOpenUseCase,
            notificationScheduler: notificationService,
            todayProvider: readingDateProvider
        )
        self.dailyReadingUseCase = DailyReadingUseCase(
            recordReadingUseCase: recordReadingUseCase,
            todayProvider: readingDateProvider
        )
        self.bookCompletionUseCase = BookCompletionUseCase(
            completeBookUseCase: completeBookUseCase,
            updateCompletionReviewUseCase: updateCompletionReviewUseCase,
            todayProvider: readingDateProvider
        )
        self.readingPlanUseCase = ReadingPlanUseCase(
            updateReadingPlanUseCase: updateReadingPlanUseCase,
            todayProvider: readingDateProvider
        )
        self.bookRegistrationUseCase = BookRegistrationUseCase(
            registerBookUseCase: registerBookUseCase
        )
        self.notificationService = notificationService
        self.notificationSettingsStore = UserDefaultsNotificationSettingsStore()
        self.bookSearchUseCase = BookSearchUseCase(bookSearchStore: APIStore())
    }

    private static func makeMigrationCompletionKey() -> String {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? defaultBundleIdentifier
        return "\(bundleIdentifier).\(migrationStoreScope).\(SwiftDataBookRepository.migrationCompletionVersionKey)"
    }
}
