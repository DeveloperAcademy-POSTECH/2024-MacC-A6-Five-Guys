//
//  AppDependencies.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/12/26.
//

import Observation
import SwiftData

@MainActor
@Observable
final class AppDependencies {
    let readingLibraryUseCase: any ReadingLibraryUsing
    let dailyReadingUseCase: any DailyReadingUsing
    let bookCompletionUseCase: any BookCompletionUsing
    let readingPlanUseCase: any ReadingPlanUsing
    let bookRegistrationUseCase: any BookRegistrationUsing
    let notificationManager: any NotificationManaging
    let notificationSettingsStore: any NotificationSettingsStoring
    private var cachedBookSearchStore: (any BookSearching)?

    init(modelContainer: ModelContainer) {
        let repository = SwiftDataBookRepository(modelContainer: modelContainer)
        let readingDateProvider = DefaultReadingDateProvider()
        let notificationManager = NotificationManager(todayProvider: readingDateProvider)
        let scheduleCalculator = ReadingScheduleCalculator()

        let fetchReadingBooksUseCase = FetchReadingBooksUseCase(repository: repository)
        let fetchCompletedBooksUseCase = FetchCompletedBooksUseCase(repository: repository)
        let deleteBookUseCase = DeleteBookUseCase(
            repository: repository,
            notificationScheduler: notificationManager
        )
        let rescheduleOnAppOpenUseCase = RescheduleOnAppOpenUseCase(
            repository: repository,
            scheduleCalculator: scheduleCalculator
        )
        let registerBookUseCase = RegisterBookUseCase(
            repository: repository,
            notificationScheduler: notificationManager,
            scheduleCalculator: scheduleCalculator
        )
        let recordReadingUseCase = RecordReadingUseCase(
            repository: repository,
            notificationScheduler: notificationManager,
            scheduleCalculator: scheduleCalculator
        )
        let completeBookUseCase = CompleteBookUseCase(
            repository: repository,
            notificationScheduler: notificationManager
        )
        let updateCompletionReviewUseCase = UpdateCompletionReviewUseCase(repository: repository)
        let updateReadingPlanUseCase = UpdateReadingPlanUseCase(
            repository: repository,
            notificationScheduler: notificationManager,
            scheduleCalculator: scheduleCalculator
        )

        self.readingLibraryUseCase = ReadingLibraryUseCase(
            fetchReadingBooksUseCase: fetchReadingBooksUseCase,
            fetchCompletedBooksUseCase: fetchCompletedBooksUseCase,
            deleteBookUseCase: deleteBookUseCase,
            rescheduleOnAppOpenUseCase: rescheduleOnAppOpenUseCase,
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
        self.notificationManager = notificationManager
        self.notificationSettingsStore = UserDefaultsNotificationSettingsStore()
    }

    func makeBookSearchStore() -> any BookSearching {
        if let cachedBookSearchStore {
            return cachedBookSearchStore
        }

        let store = APIStore()
        self.cachedBookSearchStore = store
        return store
    }
}
