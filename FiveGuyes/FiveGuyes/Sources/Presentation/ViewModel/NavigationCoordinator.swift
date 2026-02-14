//
//  NavigationCoordinator.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import SwiftUI

// TODO: 추가되는 뷰 추가하기
// 앱에서 갈 수 있는 화면 이름을 enum으로 고정합니다.
// 문자열로 직접 쓰다가 오타 나는 문제를 막기 위한 구조입니다.
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
    // 코디네이터가 공용 의존성을 들고 있다가 화면 이동 때 ViewModel을 만듭니다.
    // 생성 방식이 한곳으로 모여야 화면마다 다른 설정이 섞이는 일을 막을 수 있습니다.
    private let appDependencies: AppDependencies
    var paths = NavigationPath()
    private(set) var viewReloadTrigger = UUID()

    init(appDependencies: AppDependencies) {
        self.appDependencies = appDependencies
    }
    
    @ViewBuilder
     func navigate(to screen: Screens) -> some View {
        // TODO: 추가되는 뷰 추가하기
        // 들어온 화면 타입(enum case)에 맞춰 정확한 View를 선택합니다.
        // 이 매핑이 틀리면 다른 화면이 열리는 라우팅 버그가 생깁니다.
        switch screen {
        case .mainHome:
            MainHomeView(
                viewModel: MainHomeViewModel(
                    readingLibraryUseCase: appDependencies.readingLibraryUseCase,
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
            CompletionCelebrationView(userBook: book)
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
