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


@Observable
final class BookSettingInputModel {
    var currentPage = BookSettingsPage.bookSearch.rawValue
    var selectedBook: Book?
    var totalPages = ""
    var startData: Date?
    var endData: Date?
    var nonReadingDays: [Date] = []
    
    func nextPage() {
        withAnimation {
            currentPage += 1
        }
    }

}

struct BookSettingsManagerView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    
    @State private var bookSettingInputModel = BookSettingInputModel()
    
    var body: some View {
        VStack(spacing: 0) {
//            BookSettingProgressBar(currentPage: bookSettingInputModel.currentPage)
            ProgressBar(currentPage: bookSettingInputModel.currentPage)
            
            pageView
        }
        .navigationTitle("완독할 책 추가하기")
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
                                .tint(.gray)
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
                bookSettingInputModel.endData = nil
                bookSettingInputModel.startData = nil
            case .bookPageSetting:
                bookSettingInputModel.totalPages = ""
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
                .padding(.top, 24)
        case .bookPageSetting:
            BookPageSettingView(totalPages: bookSettingInputModel.totalPages)
                .padding(.top, 32)
        case .bookDurationSetting:
            CompletionCalendarView()
                .padding(.top, 32)
        case .bookSettingDone:
            FinishGoalView()
        case .none:
            EmptyView()
        }
        
    }
    
}

#Preview {
    BookSettingsManagerView()
}
