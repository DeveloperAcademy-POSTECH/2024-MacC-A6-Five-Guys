//
//  BookSettingsManagerView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/8/24.
//

import SwiftUI
import SwiftData

enum BookSettingsPage: Int {
    case bookSearch = 1
    case bookPageSetting
    case bookDurationSetting
    case bookNoneReadingDaySetting
    case bookSettingDone
}

struct BookSettingsManagerView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(AppDependencies.self) private var appDependencies
    
    @State private var bookSettingInputModel = BookSettingInputModel()
    @State private var pageModel = BookSettingPageModel()

    init(
        bookSettingInputModel: BookSettingInputModel = BookSettingInputModel(),
        pageModel: BookSettingPageModel = BookSettingPageModel()
    ) {
        _bookSettingInputModel = State(initialValue: bookSettingInputModel)
        _pageModel = State(initialValue: pageModel)
    }
    
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
            BookSearchView(
                viewModel: BookSearchViewModel(
                    bookSearchStore: appDependencies.makeBookSearchStore()
                )
            )
        case .bookPageSetting:
            BookPageSettingView()
        case .bookSettingDone:
            FinishGoalView(
                viewModel: FinishGoalViewModel(
                    bookManagementService: appDependencies.bookManagementService
                )
            )
        default:
            EmptyView()
        }
    }
}

#if DEBUG
#Preview("도서 검색 단계") {
    makeBookSettingsManagerPreview()
}

#Preview("페이지 설정 단계") {
    makeBookSettingsManagerPreview(
        pageAdvanceCount: 1,
        inputModel: PreviewSupport.makeBookSettingInputModel()
    )
}

#Preview("기간 선택 단계") {
    makeBookSettingsManagerPreview(
        pageAdvanceCount: 2,
        inputModel: PreviewSupport.makeBookSettingInputModel()
    )
}

#Preview("완독 목표 완료 단계") {
    makeBookSettingsManagerPreview(
        pageAdvanceCount: 4,
        inputModel: PreviewSupport.makeBookSettingInputModel()
    )
}

@MainActor
private func makeBookSettingsManagerPreview(
    pageAdvanceCount: Int = 0,
    inputModel: BookSettingInputModel = BookSettingInputModel()
) -> some View {
    let dependencies = PreviewSupport.makeDependencies()
    let coordinator = NavigationCoordinator(appDependencies: dependencies)
    let pageModel = makeBookSettingsPreviewPageModel(advanceCount: pageAdvanceCount)

    return BookSettingsManagerView(
        bookSettingInputModel: inputModel,
        pageModel: pageModel
    )
    .environment(coordinator)
    .environment(dependencies)
}

private func makeBookSettingsPreviewPageModel(advanceCount: Int) -> BookSettingPageModel {
    let model = BookSettingPageModel()
    for _ in 0..<advanceCount {
        model.nextPage()
    }
    return model
}
#endif
