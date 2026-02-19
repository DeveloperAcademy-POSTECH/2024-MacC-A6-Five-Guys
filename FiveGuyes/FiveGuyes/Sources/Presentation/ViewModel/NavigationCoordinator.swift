//
//  NavigationCoordinator.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import SwiftUI

enum ScreenRouteKey: Hashable {
    case mainHome
    case notiSetting
    case bookSettingsManager
    case totalCalendar
    case dailyProgress
    case completionCelebration
    case completionReviewUpdate
    case readingDateEdit
    case unfinishReading
}

enum Screens: Hashable {
    case mainHome
    case notiSetting(book: FGUserBook?)
    case bookSettingsManager
    case totalCalendar(books: [FGUserBook], today: Date)
    case dailyProgress(book: FGUserBook)
    case completionCelebration(book: FGUserBook)
    case completionReviewUpdate(book: FGUserBook, popToRootOnBack: Bool)
    case readingDateEdit(book: FGUserBook)
    case unfinishReading(book: FGUserBook)

    var routeKey: ScreenRouteKey {
        switch self {
        case .mainHome:
            return .mainHome
        case .notiSetting:
            return .notiSetting
        case .bookSettingsManager:
            return .bookSettingsManager
        case .totalCalendar:
            return .totalCalendar
        case .dailyProgress:
            return .dailyProgress
        case .completionCelebration:
            return .completionCelebration
        case .completionReviewUpdate:
            return .completionReviewUpdate
        case .readingDateEdit:
            return .readingDateEdit
        case .unfinishReading:
            return .unfinishReading
        }
    }
}

@Observable
@MainActor
final class NavigationCoordinator {
    private let appDependencies: AppDependencies
    var paths: [Screens] = []

    init(appDependencies: AppDependencies) {
        self.appDependencies = appDependencies
    }

    @ViewBuilder
     func navigate(to screen: Screens) -> some View {
        switch screen {
        case .mainHome:
            MainHomeView(
                viewModel: MainHomeViewModel(
                    readingLibraryUseCase: appDependencies.readingLibraryUseCase,
                    homeNotificationUseCase: appDependencies.homeNotificationUseCase
                )
            )
        case .notiSetting(book: let book):
            NotiSettingView(
                userBook: book,
                viewModel: NotiSettingViewModel(
                    notificationSettingUseCase: appDependencies.notificationSettingUseCase
                )
            )
        case .bookSettingsManager:
            BookSettingsManagerView(
                viewModel: BookSettingsManagerViewModel(
                    readingPlanUseCase: appDependencies.readingPlanUseCase
                ),
                bookSearchViewModel: BookSearchViewModel(
                    bookSearchUseCase: appDependencies.bookSearchUseCase
                ),
                finishGoalViewModel: FinishGoalViewModel(
                    bookRegistrationUseCase: appDependencies.bookRegistrationUseCase,
                    readingGoalMetricsUseCase: appDependencies.readingGoalMetricsUseCase
                ),
                readingDateSettingViewModel: ReadingDateSettingViewModel(
                    readingGoalMetricsUseCase: appDependencies.readingGoalMetricsUseCase
                )
            )
        case .totalCalendar(books: let books, today: let today):
            MultiBookProgressView(
                currentReadingBooks: books,
                today: today
            )
        case .dailyProgress(book: let book):
            DailyProgressView(
                userBook: book,
                viewModel: DailyProgressViewModel(
                    dailyReadingUseCase: appDependencies.dailyReadingUseCase,
                    bookCompletionUseCase: appDependencies.bookCompletionUseCase
                )
            )
        case .completionCelebration(book: let book):
            CompletionCelebrationView(
                userBook: book,
                viewModel: CompletionCelebrationViewModel(
                    bookCompletionUseCase: appDependencies.bookCompletionUseCase
                )
            )
        case .completionReviewUpdate(book: let book, popToRootOnBack: let popToRootOnBack):
            CompletionReviewView(
                isUpdateMode: true,
                popToRootOnBack: popToRootOnBack,
                userBook: book,
                viewModel: CompletionReviewViewModel(
                    bookCompletionUseCase: appDependencies.bookCompletionUseCase
                )
            )
        case .readingDateEdit(book: let book):
            ReadingDateEditView(
                userBook: book,
                viewModel: ReadingDateEditViewModel(
                    readingPlanUseCase: appDependencies.readingPlanUseCase
                ),
                readingDateSettingViewModel: ReadingDateSettingViewModel(
                    readingGoalMetricsUseCase: appDependencies.readingGoalMetricsUseCase
                )
            )
        case .unfinishReading(book: let book):
            UnfinishReadingView(
                userBook: book,
                viewModel: UnfinishReadingViewModel(
                    bookCompletionUseCase: appDependencies.bookCompletionUseCase
                )
            )
        }
    }

    @discardableResult
    func push(_ screen: Screens, allowDuplicateRoute: Bool = false) -> Bool {
        if !allowDuplicateRoute,
           let topScreen = paths.last,
           topScreen.routeKey == screen.routeKey {
            return false
        }

        paths.append(screen)
        return true
    }

    @discardableResult
    func pop() -> Bool {
        guard !paths.isEmpty else {
            return false
        }

        paths.removeLast()
        return true
    }

    @discardableResult
    func popToRoot() -> Bool {
        guard !paths.isEmpty else {
            return false
        }

        paths.removeAll()
        return true
    }
}
