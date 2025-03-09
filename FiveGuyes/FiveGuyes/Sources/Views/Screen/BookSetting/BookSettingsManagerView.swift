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
    case bookSettingDone
}

struct BookSettingsManagerView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    
    @State private var bookSettingInputModel = BookSettingInputModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            pageView
            
            if bookSettingInputModel.currentPage != 4 {
                BookSettingProgressBar(currentPage: bookSettingInputModel.currentPage)
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
    }
    
    private func handleBackButton() {
        if bookSettingInputModel.currentPage > BookSettingsPage.bookSearch.rawValue {
            clearBookSetting()
            withAnimation {
                bookSettingInputModel.currentPage -= 1
            }
        } else {
            navigationCoordinator.pop()
        }
    }
    
    private func clearBookSetting() {
        if let page = BookSettingsPage(rawValue: bookSettingInputModel.currentPage) {
            switch page {
            case .bookDurationSetting:
                bookSettingInputModel.clearReadingPeriod()
            case .bookPageSetting:
                bookSettingInputModel.clearPageRange()
            case .bookSearch:
                return
            case .bookSettingDone:
                return
            }
        }
    }
    
    @ViewBuilder
    private var pageView: some View {
        switch BookSettingsPage(rawValue: bookSettingInputModel.currentPage) {
        case .bookSearch:
            BookSearchView()
        case .bookPageSetting:
            BookPageSettingView()
        case .bookDurationSetting:
            ReadingDateSettingView()
        case .bookSettingDone:
            FinishGoalView()
        case .none:
            EmptyView()
        }
        
    }
    
}

#Preview {
    BookSettingsManagerView()
        .environment(NavigationCoordinator())
}
