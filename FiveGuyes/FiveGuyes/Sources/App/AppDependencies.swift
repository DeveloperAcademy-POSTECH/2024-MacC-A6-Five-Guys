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
    let homeNotificationUseCase: any HomeNotificationUsing
    let dailyReadingUseCase: any DailyReadingUsing
    let bookCompletionUseCase: any BookCompletionUsing
    let readingPlanUseCase: any ReadingPlanUsing
    let readingGoalMetricsUseCase: any ReadingGoalMetricsUsing
    let bookRegistrationUseCase: any BookRegistrationUsing
    let notificationSettingUseCase: any NotificationSettingUsing
    let notificationService: any NotificationManaging
    let notiSettingsStore: any NotificationSettingsStoring
    let systemSettingsOpener: any SystemSettingsOpening
    let bookSearchUseCase: any BookSearchUsing

    init(modelContainer: ModelContainer) {
        let migrationCompletionKey = Self.makeMigrationCompletionKey()
        let repo = SwiftDataBookRepo(
            modelContainer: modelContainer,
            migrationUserDefaults: .standard,
            migrationCompletionKey: migrationCompletionKey
        )

        do {
            try repo.prewarmReadingRecordKeyMigrationIfNeeded()
        } catch {
            print(
                "[MigrationPrewarm] failed key=\(migrationCompletionKey) " +
                "errorType=\(String(describing: type(of: error))) message=\(error.localizedDescription)"
            )
        }

        let readingDateProvider = DefaultReadingDateProvider()
        let readingTimeZoneProvider = SystemReadingTimeZoneProvider()
        let notiSettingsStore = UserDefaultsNotificationSettingsStore()
        let systemSettingsOpener = SystemSettingsManager()
        let notificationService = NotificationManager(
            todayProvider: readingDateProvider,
            settingsStore: notiSettingsStore
        )
        let notificationSettingUseCase = NotificationSettingUseCase(
            notificationService: notificationService,
            systemSettingsOpener: systemSettingsOpener,
            settingsStore: notiSettingsStore
        )
        let homeNotificationUseCase = HomeNotificationUseCase(
            notificationScheduler: notificationService
        )
        let scheduleCalculator = ReadingScheduleCalculator()
        let readingGoalMetricsUseCase = ReadingGoalMetricsUseCase()

        let fetchReadingBooksUseCase = FetchReadingBooksUseCase(repo: repo)
        let fetchCompletedBooksUseCase = FetchCompletedBooksUseCase(repo: repo)
        let deleteBookUseCase = DeleteBookUseCase(
            repo: repo,
            notificationScheduler: notificationService
        )
        let rescheduleOnAppOpenUseCase = RescheduleOnAppOpenUseCase(
            repo: repo,
            scheduleCalculator: scheduleCalculator,
            timeZoneProvider: readingTimeZoneProvider
        )
        let registerBookUseCase = RegisterBookUseCase(
            repo: repo,
            notificationScheduler: notificationService,
            scheduleCalculator: scheduleCalculator,
            timeZoneProvider: readingTimeZoneProvider
        )
        let recordReadingUseCase = RecordReadingUseCase(
            repo: repo,
            notificationScheduler: notificationService,
            scheduleCalculator: scheduleCalculator,
            timeZoneProvider: readingTimeZoneProvider
        )
        let completeBookUseCase = CompleteBookUseCase(
            repo: repo,
            notificationScheduler: notificationService
        )
        let updateCompletionReviewUseCase = UpdateCompletionReviewUseCase(repo: repo)
        let updateReadingPlanUseCase = UpdateReadingPlanUseCase(
            repo: repo,
            notificationScheduler: notificationService,
            scheduleCalculator: scheduleCalculator,
            timeZoneProvider: readingTimeZoneProvider
        )

        self.readingLibraryUseCase = ReadingLibraryUseCase(
            fetchReadingBooksUseCase: fetchReadingBooksUseCase,
            fetchCompletedBooksUseCase: fetchCompletedBooksUseCase,
            deleteBookUseCase: deleteBookUseCase,
            rescheduleOnAppOpenUseCase: rescheduleOnAppOpenUseCase,
            todayProvider: readingDateProvider
        )
        self.homeNotificationUseCase = homeNotificationUseCase
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
        self.readingGoalMetricsUseCase = readingGoalMetricsUseCase
        self.bookRegistrationUseCase = BookRegistrationUseCase(
            registerBookUseCase: registerBookUseCase
        )
        self.notificationSettingUseCase = notificationSettingUseCase
        self.notificationService = notificationService
        self.notiSettingsStore = notiSettingsStore
        self.systemSettingsOpener = systemSettingsOpener
        self.bookSearchUseCase = BookSearchUseCase(
            bookSearchProvider: AladinBookSearchProvider()
        )
    }

    private static func makeMigrationCompletionKey() -> String {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? defaultBundleIdentifier
        return "\(bundleIdentifier).\(migrationStoreScope).\(SwiftDataBookRepo.migrationCompletionVersionKey)"
    }
}
