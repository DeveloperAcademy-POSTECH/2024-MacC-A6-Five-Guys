//
//  BookSettingsManagerView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/8/24.
//

import SwiftUI

enum BookSettingsPage: Int {
    case bookSearch = 1
    case bookPageSetting
    case bookDurationSetting
    case bookNoneReadingDaySetting
    case bookSettingDone
}

struct BookSettingsManagerView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    
    @State private var bookSettingInputModel = BookSettingInputModel()
    @State private var pageModel = BookSettingPageModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            if [BookSettingsPage.bookDurationSetting.rawValue,
                BookSettingsPage.bookNoneReadingDaySetting.rawValue]
                .contains(pageModel.currentPage) {
                ReadingDateSettingView()
            } else {
                pageView
            }
            
            if pageModel.currentPage != BookSettingsPage.bookSettingDone.rawValue {
                BookSettingProgressBar(currentPage: pageModel.currentPage)
                    .padding(.top, 5)
                    .padding(.horizontal, 20)
            }
        }
        .background(Color.Fills.white)
        .navigationTitle("완독할 책 추가하기")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    handleBackButton()
                } label: {
                    HStack(spacing: 3) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                                .tint(Color.Labels.tertiaryBlack3)
                        }
                    }
                }
            }
        }
        .environment(bookSettingInputModel)
        .environment(pageModel)
    }
    
    private func handleBackButton() {
        if pageModel.currentPage > BookSettingsPage.bookSearch.rawValue {
            clearBookSetting()
            withAnimation(.easeOut) {
                pageModel.previousPage()
            }
        } else {
            navigationCoordinator.pop()
        }
    }
    
    private func clearBookSetting() {
        if let page = BookSettingsPage(rawValue: pageModel.currentPage) {
            switch page {
            case .bookNoneReadingDaySetting:
                bookSettingInputModel
                    .clearNonReadingDays()
            case .bookDurationSetting:
                bookSettingInputModel
                    .clearReadingPeriod()
            case .bookPageSetting:
                bookSettingInputModel
                    .clearPageRange()
            default:
                return
            }
        }
    }
    
    @ViewBuilder
    private var pageView: some View {
        switch BookSettingsPage(rawValue: pageModel.currentPage) {
        case .bookSearch:
            BookSearchView()
        case .bookPageSetting:
            BookPageSettingView()
        case .bookSettingDone:
            FinishGoalView()
        default:
            EmptyView()
        }
    }
}

#Preview {
    BookSettingsManagerView()
        .environment(NavigationCoordinator())
}
