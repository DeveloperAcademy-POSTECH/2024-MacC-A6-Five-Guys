//
//  BookPageSettingView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import SwiftUI

struct BookPageSettingView: View {
    private enum FieldFocus {
        case firstField
        case secondField
    }
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(BookSettingInputModel.self) var bookSettingInputModel: BookSettingInputModel
    
    @State private var startPage: String = "1"
    @State private var targetEndPage: String = ""
    
    @FocusState private var focusedField: FieldFocus?
    
    @StateObject private var toastViewModel = ToastViewModel()
    
    // TODO: 사용자 입력 값 유효성 검사 로직 추가 (ex. 시작 페이지 < 끝 페이지) 🐯🐯🐯🐯🐯
    var body: some View {
        let title = bookSettingInputModel.selectedBook?.title ?? "제목 없음"
        
        VStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text("<\(title)>\(title.subjectParticle())")
                    .lineLimit(nil) // 제목이 길어지면 줄바꿈 허용
                
                HStack(spacing: 8) {
                    Text("총")
                    
                    // 첫 번째 텍스트 필드
                    pageNumberTextField(
                        page: $startPage,
                        isFocused: $focusedField,
                        field: .firstField
                    )
                    
                    Text("쪽 부터")
                    
                    // 두 번째 텍스트 필드
                    pageNumberTextField(
                        page: $targetEndPage,
                        isFocused: $focusedField,
                        field: .secondField
                    )
                    
                    Text("쪽이에요")
                    
                    Spacer()
                }
            }
            .padding(.top, 34)
            .padding(.horizontal, 20)
            
            Spacer()
            
            if focusedField != nil {
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
            
        }
        .fontStyle(.title2, weight: .semibold)
        .foregroundStyle(Color.Labels.primaryBlack1)
        .background(.white)
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
        page: Binding<String>,
        isFocused: FocusState<FieldFocus?>.Binding,
        field: FieldFocus
    ) -> some View {
        TextField("", text: page)
            .keyboardType(.numberPad)
            .focused(isFocused, equals: field)
            .fontStyle(.title2, weight: .semibold)
            .foregroundStyle(Color.Colors.green2)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(Color.Fills.lightGreen)
            }
    }
    
    private func nextButtonTapped() {
        if targetEndPage > startPage {
            bookSettingInputModel.targetEndPage = targetEndPage
            bookSettingInputModel.startPage = startPage
            
            focusedField = nil
            bookSettingInputModel.nextPage()
            return
        }
        
        let message = startPage > targetEndPage
            ? "앗! 시작 페이지는 마지막 페이지를 초과할 수 없어요!"
            : "시작 페이지는 마지막 페이지와 같을 수 없어요!"
        
        toastViewModel.showToast(message: message)
    }
    
    private func initializePageSettings() {
        targetEndPage = bookSettingInputModel.startPage
        targetEndPage = bookSettingInputModel.targetEndPage
        focusedField = .secondField
    }
    
    private func trackPageSettingScreen() {
        Tracking.Screen.pageSetting.setTracking()
    }
}
