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
    @State private var viewModel: BookSettingsManagerViewModel
    @State private var bookSearchViewModel: BookSearchViewModel
    @State private var finishGoalViewModel: FinishGoalViewModel
    @State private var readingDateSettingViewModel: ReadingDateSettingViewModel
    @State private var bookSettingInputModel = BookSettingInputModel()
    @State private var pageModel = BookSettingPageModel()

    init(
        viewModel: BookSettingsManagerViewModel,
        bookSearchViewModel: BookSearchViewModel,
        finishGoalViewModel: FinishGoalViewModel,
        readingDateSettingViewModel: ReadingDateSettingViewModel,
        bookSettingInputModel: BookSettingInputModel = BookSettingInputModel(),
        pageModel: BookSettingPageModel = BookSettingPageModel()
    ) {
        _viewModel = State(initialValue: viewModel)
        _bookSearchViewModel = State(initialValue: bookSearchViewModel)
        _finishGoalViewModel = State(initialValue: finishGoalViewModel)
        _readingDateSettingViewModel = State(initialValue: readingDateSettingViewModel)
        _bookSettingInputModel = State(initialValue: bookSettingInputModel)
        _pageModel = State(initialValue: pageModel)
    }

    var body: some View {
        ZStack(alignment: .top) {
            if [BookSettingsPage.bookDurationSetting.rawValue,
                BookSettingsPage.bookNoneReadingDaySetting.rawValue]
                .contains(pageModel.currentPage) {
                ReadingDateSettingView(
                    today: viewModel.today(),
                    viewModel: readingDateSettingViewModel
                )
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
        .customNavigationBackButton(
            routeKey: .bookSettingsManager,
            beforeBackAction: {
                // 단계 전환은 이 화면의 로컬 상태(page/input) 책임이므로 뷰에서 처리합니다.
                if isEditingBookSettingFlow {
                    clearBookSetting()
                    withAnimation(.easeOut) {
                        pageModel.previousPage()
                    }
                    return .cancel
                }

                return .proceed
            }
        )
        .environment(bookSettingInputModel)
        .environment(pageModel)
    }

    private var isEditingBookSettingFlow: Bool {
        pageModel.currentPage > BookSettingsPage.bookSearch.rawValue
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
            BookSearchView(viewModel: bookSearchViewModel)
        case .bookPageSetting:
            BookPageSettingView()
        case .bookSettingDone:
            FinishGoalView(viewModel: finishGoalViewModel)
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
    let managerViewModel = BookSettingsManagerViewModel(
        readingPlanUseCase: dependencies.readingPlanUseCase
    )
    let bookSearchViewModel = BookSearchViewModel(
        bookSearchUseCase: dependencies.bookSearchUseCase
    )
    let finishGoalViewModel = FinishGoalViewModel(
        bookRegistrationUseCase: dependencies.bookRegistrationUseCase,
        readingGoalMetricsUseCase: dependencies.readingGoalMetricsUseCase
    )
    let readingDateSettingViewModel = ReadingDateSettingViewModel(
        readingGoalMetricsUseCase: dependencies.readingGoalMetricsUseCase
    )
    let pageModel = makeBookSettingsPreviewPageModel(advanceCount: pageAdvanceCount)

    return BookSettingsManagerView(
        viewModel: managerViewModel,
        bookSearchViewModel: bookSearchViewModel,
        finishGoalViewModel: finishGoalViewModel,
        readingDateSettingViewModel: readingDateSettingViewModel,
        bookSettingInputModel: inputModel,
        pageModel: pageModel
    )
    .environment(coordinator)
}

private func makeBookSettingsPreviewPageModel(advanceCount: Int) -> BookSettingPageModel {
    let model = BookSettingPageModel()
    for _ in 0..<advanceCount {
        model.nextPage()
    }
    return model
}
#endif
