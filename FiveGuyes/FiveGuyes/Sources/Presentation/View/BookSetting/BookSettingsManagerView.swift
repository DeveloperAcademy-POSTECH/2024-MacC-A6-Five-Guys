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
    @Environment(AppDependencies.self) private var appDependencies
    
    @State private var viewModel: BookSettingsManagerViewModel
    @State private var bookSettingInputModel = BookSettingInputModel()
    @State private var pageModel = BookSettingPageModel()

    // 필요한 값을 밖에서 받아 시작할 수 있게 만든 생성자입니다.
    // 이렇게 해야 프리뷰/테스트에서 원하는 상황을 정확히 다시 만들 수 있습니다.
    init(
        viewModel: BookSettingsManagerViewModel,
        bookSettingInputModel: BookSettingInputModel = BookSettingInputModel(),
        pageModel: BookSettingPageModel = BookSettingPageModel()
    ) {
        _viewModel = State(initialValue: viewModel)
        _bookSettingInputModel = State(initialValue: bookSettingInputModel)
        _pageModel = State(initialValue: pageModel)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            if [BookSettingsPage.bookDurationSetting.rawValue,
                BookSettingsPage.bookNoneReadingDaySetting.rawValue]
                .contains(pageModel.currentPage) {
                ReadingDateSettingView(today: viewModel.today())
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
                    bookSearchUseCase: appDependencies.bookSearchUseCase
                )
            )
        case .bookPageSetting:
            BookPageSettingView()
        case .bookSettingDone:
            FinishGoalView(
                viewModel: FinishGoalViewModel(
                    bookRegistrationUseCase: appDependencies.bookRegistrationUseCase
                )
            )
        default:
            EmptyView()
        }
    }
}

#if DEBUG
// 이 프리뷰는 "도서 검색 단계" 화면을 바로 열어,
// 입력 없이도 이 분기 UI가 맞는지 빠르게 확인하려고 만든 예시입니다.
#Preview("도서 검색 단계") {
    makeBookSettingsManagerPreview()
}

// 이 프리뷰는 "페이지 설정 단계" 화면을 바로 열어,
// 입력 없이도 이 분기 UI가 맞는지 빠르게 확인하려고 만든 예시입니다.
#Preview("페이지 설정 단계") {
    makeBookSettingsManagerPreview(
        pageAdvanceCount: 1,
        inputModel: PreviewSupport.makeBookSettingInputModel()
    )
}

// 이 프리뷰는 "기간 선택 단계" 화면을 바로 열어,
// 입력 없이도 이 분기 UI가 맞는지 빠르게 확인하려고 만든 예시입니다.
#Preview("기간 선택 단계") {
    makeBookSettingsManagerPreview(
        pageAdvanceCount: 2,
        inputModel: PreviewSupport.makeBookSettingInputModel()
    )
}

// 이 프리뷰는 "완독 목표 완료 단계" 화면을 바로 열어,
// 입력 없이도 이 분기 UI가 맞는지 빠르게 확인하려고 만든 예시입니다.
#Preview("완독 목표 완료 단계") {
    makeBookSettingsManagerPreview(
        pageAdvanceCount: 4,
        inputModel: PreviewSupport.makeBookSettingInputModel()
    )
}

// 화면 값은 메인 스레드에서만 바꿔야 안전합니다.
// 이 표시를 붙여, 다른 스레드가 끼어들어 상태가 꼬이는 일을 막습니다.
@MainActor
// 여러 프리뷰에서 반복되는 준비 코드를 한곳으로 모은 함수입니다.
// 복붙을 줄여서 상태 설정이 서로 달라지는 실수를 막습니다.
private func makeBookSettingsManagerPreview(
    pageAdvanceCount: Int = 0,
    inputModel: BookSettingInputModel = BookSettingInputModel()
) -> some View {
    // 프리뷰가 실제 앱과 비슷한 구조로 동작하도록 같은 의존성 묶음을 만듭니다.
    // 구조가 다르면 프리뷰에서만 보이는 버그를 놓치기 쉽습니다.
    let dependencies = PreviewSupport.makeDependencies()
    // 프리뷰에서도 화면 이동을 직접 눌러볼 수 있게 네비게이션 객체를 넣습니다.
    // 이동 경로 버그를 출시 전에 확인하려는 목적입니다.
    let coordinator = NavigationCoordinator(appDependencies: dependencies)
    // 원하는 단계 화면을 바로 보려고 페이지 단계를 미리 앞으로 이동시킵니다.
    // 이 값을 맞추면 중간 단계를 매번 반복하지 않아도 됩니다.
    let viewModel = BookSettingsManagerViewModel(
        readingPlanUseCase: dependencies.readingPlanUseCase
    )
    let pageModel = makeBookSettingsPreviewPageModel(advanceCount: pageAdvanceCount)

    return BookSettingsManagerView(
        viewModel: viewModel,
        bookSettingInputModel: inputModel,
        pageModel: pageModel
    )
    .environment(coordinator)
    .environment(dependencies)
}

// 프리뷰에서 원하는 단계 화면을 바로 열기 위해 페이지 상태를 미리 이동시킵니다.
private func makeBookSettingsPreviewPageModel(advanceCount: Int) -> BookSettingPageModel {
    let model = BookSettingPageModel()
    for _ in 0..<advanceCount {
        model.nextPage()
    }
    return model
}
#endif
