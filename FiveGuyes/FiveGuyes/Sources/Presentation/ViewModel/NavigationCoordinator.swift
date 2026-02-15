//
//  NavigationCoordinator.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import SwiftUI

// TODO: 추가되는 뷰 추가하기
enum Screens: Hashable {
    case mainHome
    case notiSetting(book: FGUserBook?)
    case bookSettingsManager
    case totalCalendar(books: [FGUserBook])
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
        // TODO: 추가되는 뷰 추가하기
        switch screen {
        case .mainHome:
            MainHomeView(
                viewModel: MainHomeViewModel(
                    bookManagementService: appDependencies.bookManagementService,
                    notificationManager: appDependencies.notificationManager
                )
            )
        case .notiSetting(book: let book):
            NotiSettingView(
                userBook: book,
                viewModel: NotiSettingViewModel(
                    notificationManager: appDependencies.notificationManager,
                    settingsStore: appDependencies.notificationSettingsStore
                )
            )
        case .bookSettingsManager:
            BookSettingsManagerView()
        case .totalCalendar(books: let books):
            MultiBookProgressView(currentReadingBooks: books)
        case .dailyProgress(book: let book):
            DailyProgressView(
                userBook: book,
                viewModel: DailyProgressViewModel(
                    bookManagementService: appDependencies.bookManagementService
                )
            )
        case .completionCelebration(book: let book):
            CompletionCelebrationView(userBook: book)
        case .completionReview(book: let book):
            CompletionReviewView(
                userBook: book,
                viewModel: CompletionReviewViewModel(
                    bookManagementService: appDependencies.bookManagementService
                )
            )
        case .completionReviewUpdate(book: let book):
            CompletionReviewView(
                isUpdateMode: true,
                userBook: book,
                viewModel: CompletionReviewViewModel(
                    bookManagementService: appDependencies.bookManagementService
                )
            )
        case .readingDateEdit(book: let book):
            ReadingDateEditView(
                userBook: book,
                viewModel: ReadingDateEditViewModel(
                    bookManagementService: appDependencies.bookManagementService
                )
            )
        case .unfinishReading(book: let book):
            UnfinishReadingView(
                userBook: book,
                viewModel: UnfinishReadingViewModel(
                    bookManagementService: appDependencies.bookManagementService
                )
            )
        }
    }

    // add screen
    func push(_ screen: Screens) {
        paths.append(screen)
    }

    // remove last screen
    func pop() {
        paths.removeLast()
    }

    // go to root screen
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
