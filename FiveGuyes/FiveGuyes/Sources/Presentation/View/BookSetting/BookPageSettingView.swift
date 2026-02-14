//
//  BookPageSettingView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import SwiftUI

struct BookPageSettingView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(BookSettingInputModel.self) var bookSettingInputModel: BookSettingInputModel
    @Environment(BookSettingPageModel.self) var pageModel: BookSettingPageModel
    
    @State private var startPage = 1
    @State private var targetEndPage = 0
    
    @State private var isStartPageFieldFoucsed: Bool = false
    @State private var isEndPageFieldFoucsed: Bool = true
    
    @StateObject private var toastViewModel = ToastViewModel()
    
    var body: some View {
        let title = bookSettingInputModel.selectedBook?.title ?? "제목 없음"
        
        VStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text("<\(title)>\(title.subjectParticle())")
                    .lineLimit(nil) // 제목이 길어지면 줄바꿈 허용
                
                HStack(spacing: 8) {
                    Text("총")
                    // 시작 페이지 입력 텍스트 필드
                    pageNumberTextField(
                        page: $startPage,
                        isFocused: $isStartPageFieldFoucsed
                    )
                    
                    Text("쪽 부터")
                    
                    // 마지막 페이지 입력 텍스트 필드
                    pageNumberTextField(
                        page: $targetEndPage,
                        isFocused: $isEndPageFieldFoucsed
                    )
                    
                    Text("쪽이에요")
                    
                    Spacer()
                }
            }
            .fontStyle(.title2, weight: .semibold)
            .padding(.top, 34)
            .padding(.horizontal, 20)
            
            Spacer()
            
            VStack(spacing: 22) {
                ToastView(viewModel: toastViewModel)
                
                Button(action: nextButtonTapped) {
                    Text("다음")
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.Colors.green1)
                        .foregroundStyle(Color.Fills.white)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .fontStyle(.title2, weight: .semibold)
        .foregroundStyle(Color.Labels.primaryBlack1)
        .background(Color.Fills.white)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("다음")
                    .fontStyle(.body)
                    .foregroundStyle(Color.Labels.tertiaryBlack3)
            }
        }
        .onAppear {
            initializePageSettings()
            trackPageSettingScreen()
        }
    }
    
    // 텍스트 필드 생성 메서드
    private func pageNumberTextField(
        page: Binding<Int>,
        isFocused: Binding<Bool>
    ) -> some View {
        // UIKit의 UITextField를 SwiftUI로 래핑
        CustomTextFieldRepresentable(
            text: page,
            isFocused: isFocused
        )
        .frame(height: 40)
        .fixedSize()
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(Color.Fills.lightGreen)
        }
    }
    
    private func nextButtonTapped() {
        if let message = pageValidationError() {
            toastViewModel.showToast(message: message)
            return
        }
        
        bookSettingInputModel.setPageRange(start: startPage, end: targetEndPage)
        
        dismissKeyboard()
        pageModel.nextPage()
    }
    
    /// 시작 페이지와 마지막 페이지의 입력값을 검증하여, 오류가 있으면 에러 메시지를 반환합니다.
    /// 유효한 입력이면 nil을 반환합니다.
    private func pageValidationError() -> String? {
        if startPage <= 0 {
            return "시작 페이지를 0보다 큰 페이지로 입력해주세요!"
        } else if startPage > targetEndPage {
            return "앗! 시작 페이지는 마지막 페이지를 초과할 수 없어요!"
        } else if startPage == targetEndPage {
            return "시작 페이지는 마지막 페이지와 같을 수 없어요!"
        }
        return nil
    }
    
    private func initializePageSettings() {
        targetEndPage = bookSettingInputModel.startPage
        targetEndPage = bookSettingInputModel.targetEndPage
    }
    
    private func trackPageSettingScreen() {
        Tracking.Screen.pageSetting.setTracking()
    }
    
    private func dismissKeyboard() {
        isStartPageFieldFoucsed = false
        isEndPageFieldFoucsed = false
    }
}

#if DEBUG
// 이 프리뷰는 "책 정보 있음" 화면을 바로 열어,
// 입력 없이도 이 분기 UI가 맞는지 빠르게 확인하려고 만든 예시입니다.
#Preview("책 정보 있음") {
    // 프리뷰에서 단계 화면을 바로 보여주려고 입력 모델을 먼저 채워 둡니다.
    // 초기값이 있어야 다음 단계 UI를 안정적으로 확인할 수 있습니다.
    let inputModel = PreviewSupport.makeBookSettingInputModel()
    // 원하는 단계 화면을 바로 보려고 페이지 단계를 미리 앞으로 이동시킵니다.
    // 이 값을 맞추면 중간 단계를 매번 반복하지 않아도 됩니다.
    let pageModel = BookSettingPageModel()

    NavigationStack {
        BookPageSettingView()
    }
    .environment(PreviewSupport.makeCoordinator())
    .environment(inputModel)
    .environment(pageModel)
}

// 이 프리뷰는 "책 정보 없음" 화면을 바로 열어,
// 입력 없이도 이 분기 UI가 맞는지 빠르게 확인하려고 만든 예시입니다.
#Preview("책 정보 없음") {
    // 프리뷰에서 단계 화면을 바로 보여주려고 입력 모델을 먼저 채워 둡니다.
    // 초기값이 있어야 다음 단계 UI를 안정적으로 확인할 수 있습니다.
    let inputModel = BookSettingInputModel()
    // 원하는 단계 화면을 바로 보려고 페이지 단계를 미리 앞으로 이동시킵니다.
    // 이 값을 맞추면 중간 단계를 매번 반복하지 않아도 됩니다.
    let pageModel = BookSettingPageModel()

    NavigationStack {
        BookPageSettingView()
    }
    .environment(PreviewSupport.makeCoordinator())
    .environment(inputModel)
    .environment(pageModel)
}
#endif
