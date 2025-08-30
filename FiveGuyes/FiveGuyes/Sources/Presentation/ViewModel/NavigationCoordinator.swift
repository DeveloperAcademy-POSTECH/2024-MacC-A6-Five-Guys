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
    case totalCalendar(books: [FGUserBook])
    case dailyProgress(book: UserBook)
    case completionCelebration(book: UserBook)
    case completionReview(book: UserBook)
    case completionReviewUpdate(book: UserBook)
    case readingDateEdit(book: UserBook)
    case unfinishReading(book: UserBook)
}

@Observable
final class NavigationCoordinator {
    var paths = NavigationPath()
    private(set) var viewReloadTrigger = UUID()
    
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
        case .totalCalendar(books: let books):
            MultiBookProgressView(currentReadingBooks: books)
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
        case .unfinishReading(book: let book):
            UnfinishReadingView(userBook: book)
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
