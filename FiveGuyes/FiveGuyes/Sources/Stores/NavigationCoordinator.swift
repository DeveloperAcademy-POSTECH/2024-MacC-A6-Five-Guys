//
//  NavigationCoordinator.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import SwiftUI

// TODO: 추가되는 뷰 추가하기
enum Screens: Hashable {
    typealias UserBook = UserBookSchemaV2.UserBookV2
    case empty
    case mainHome
    case notiSetting(book: UserBook?)
    case bookSettingsManager
    case totalCalendar(book: UserBook)
    case dailyProgress(book: UserBook)
    case completionCelebration(book: UserBook)
    case completionReview(book: UserBook)
    case completionReviewUpdate(book: UserBook)
    case readingDateEdit(book: UserBook)
}

@Observable
final class NavigationCoordinator {
    var paths = NavigationPath()

    @ViewBuilder
     func navigate(to screen: Screens) -> some View {
         // TODO: 추가되는 뷰 추가하기
        switch screen {
        case .empty: EmptyView()
        case .mainHome: 
            MainHomeView()
        case .notiSetting(book: let book):
            NotiSettingView(userBook: book)
        case .bookSettingsManager:
            BookSettingsManagerView()
        case .totalCalendar(book: let book):
            TotalCalendarView(currentReadingBook: book)
        case .dailyProgress(book: let book):
            DailyProgressView(userBook: book)
        case .completionCelebration(book: let book):
            CompletionCelebrationView(userBook: book)
        case .completionReview(book: let book):
            CompletionReviewView(userBook: book)
        case .completionReviewUpdate(book: let book):
            CompletionReviewView(isUpdateMode: true, userBook: book)
        case .readingDateEdit(book: let book):
            ReadingDateEditView(userBook: book)
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
}
