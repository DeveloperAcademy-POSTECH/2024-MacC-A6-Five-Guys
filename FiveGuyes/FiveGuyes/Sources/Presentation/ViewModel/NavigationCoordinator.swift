//
//  NavigationCoordinator.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import SwiftUI

enum Screens: Hashable {
    case mainHome
    case notiSetting(book: FGUserBook?)
    case bookSettingsManager
    case totalCalendar(books: [FGUserBook], today: Date)
    case dailyProgress(book: FGUserBook)
    case completionCelebration(book: FGUserBook)
    case completionReview(book: FGUserBook)
    case completionReviewUpdate(book: FGUserBook)
    case readingDateEdit(book: FGUserBook)
    case unfinishReading(book: FGUserBook)
}

@Observable
@MainActor
final class NavigationCoordinator {
    private let appDependencies: AppDependencies
    var paths = NavigationPath()
    private(set) var viewReloadTrigger = UUID()

    init(appDependencies: AppDependencies) {
        self.appDependencies = appDependencies
    }

    @ViewBuilder
     func navigate(to screen: Screens) -> some View {
        switch screen {
        case .mainHome:
            MainHomeView(
                viewModel: MainHomeViewModel(
                    readingLibraryUseCase: appDependencies.readingLibraryUseCase
                )
            )
        case .notiSetting(book: let book):
            NotiSettingView(
                userBook: book,
                viewModel: NotiSettingViewModel(
                    notificationService: appDependencies.notificationService,
                    settingsStore: appDependencies.notiSettingsStore
                )
            )
        case .bookSettingsManager:
            BookSettingsManagerView(
                viewModel: BookSettingsManagerViewModel(
                    readingPlanUseCase: appDependencies.readingPlanUseCase
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
                    dailyReadingUseCase: appDependencies.dailyReadingUseCase
                )
            )
        case .completionCelebration(book: let book):
            CompletionCelebrationView(
                userBook: book,
                viewModel: CompletionCelebrationViewModel(
                    bookCompletionUseCase: appDependencies.bookCompletionUseCase
                )
            )
        case .completionReview(book: let book):
            CompletionReviewView(
                userBook: book,
                viewModel: CompletionReviewViewModel(
                    bookCompletionUseCase: appDependencies.bookCompletionUseCase
                )
            )
        case .completionReviewUpdate(book: let book):
            CompletionReviewView(
                isUpdateMode: true,
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

    func push(_ screen: Screens) {
        paths.append(screen)
    }

    func pop() {
        paths.removeLast()
    }

    func popToRoot() {
        paths.removeLast(paths.count)
    }

    func reloadView() {
        viewReloadTrigger = UUID()
    }

    func getViewReloadTrigger() -> UUID {
        viewReloadTrigger
    }
}
