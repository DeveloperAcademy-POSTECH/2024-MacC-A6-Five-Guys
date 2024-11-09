//
//  NavigationCoordinator.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import SwiftUI

// TODO: 추가되는 뷰 추가하기
enum Screens: Hashable {
    case empty
    case mainHome
    case empthNoti
    case bookSettingsManager
    case totalCalendar
    case dailyProgress
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
        case .empthNoti:
            EmptyNotiView()
        case .bookSettingsManager:
            BookSettingsManagerView()
        case .totalCalendar:
            TotalCalendarView()
        case .dailyProgress:
            DailyProgressView()
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
