//
//  FinishGoalView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/4/24.
//

import SwiftUI

struct FinishGoalView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(BookSettingInputModel.self) var bookSettingInputModel: BookSettingInputModel
    
    @State private var viewModel: FinishGoalViewModel

    init(viewModel: FinishGoalViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        
        if let book = bookSettingInputModel.selectedBook,
           let startDate = bookSettingInputModel.startDate,
           let endDate = bookSettingInputModel.endDate {
            
            let startPage = bookSettingInputModel.startPage
            let totalPages = bookSettingInputModel.targetEndPage
            
            ZStack {
                Color.Fills.lightGreen
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 56, height: 56)
                        .foregroundStyle(Color.Colors.green1)
                        .padding(.bottom, 14)
                    
                    Text("완독 목표 설정 완료")
                        .fontStyle(.title2, weight: .semibold)
                        .foregroundStyle(Color.Colors.green2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.Fills.white)
                        .cornerRadius(8)
                        .padding(.bottom, 40)
                    
                    HStack(spacing: 0) {
                        TextView(text: "매일 ")
                        
                        Text("\(viewModel.pagesPerDay)")
                            .fontStyle(.title1, weight: .semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundStyle(Color.Colors.green2)
                            .background(Color.Fills.white)
                            .cornerRadius(8)
                        
                        TextView(text: " 쪽만 읽으면")
                    }
                    .padding(.bottom, 3)
                    
                    TextView(text: "완독할 수 있어요!")
                        .padding(.bottom, 48)
                    
                    /// book card view
                    HStack(spacing: 16) {
                        if let coverUrl = book.cover, let url = URL(string: coverUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 90, height: 139)
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            // 이미지 없을 때
                            Rectangle()
                                .foregroundStyle(Color.Colors.green) // TODO: 확인필요 / 일반 .green 으로 되어있었음
                                .frame(width: 90, height: 139)
                                .padding(.leading, 20)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            VStack(alignment: .leading, spacing: 0) {
                                // 책 제목
                                Text(book.title)
                                    .fontStyle(.body, weight: .semibold)
                                    .padding(.top, 17)
                                    .foregroundStyle(Color.Labels.primaryBlack1)
                                    .lineLimit(1)
                                
                                // 저자
                                Text(book.author.removingParenthesesContent())
                                    .fontStyle(.caption1)
                                    .foregroundStyle(Color.Labels.secondaryBlack2)
                                    .lineLimit(1)
                            }
                            
                            // 완독 목표 기간
                            Text("\(startDate.toKoreanDateStringWithoutYear()) ~ \(endDate.toKoreanDateStringWithoutYear())")
                                .foregroundStyle(Color.Labels.primaryBlack1)
                                .fontStyle(.body)
                                .lineLimit(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.Fills.lightGreen)
                                .cornerRadius(8)
                            
                            // 하루 권장 독서량
                            Text("하루 권장 독서량 : \(viewModel.pagesPerDay)쪽")
                                .foregroundStyle(Color.Colors.green2)
                                .fontStyle(.body)
                                .lineLimit(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.Fills.lightGreen)
                                .cornerRadius(8)
                                .padding(.bottom, 16)
                            
                        }
                        
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.Fills.white)
                            .commonShadow()
                    }
                    .padding(.horizontal, 44)
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await registerBook(
                                selectedBook: book,
                                startPage: startPage,
                                targetEndPage: totalPages,
                                startDate: startDate,
                                endDate: endDate
                            )
                        }
                    } label: {
                        HStack {
                            Text("확인")
                                .fontStyle(.title2, weight: .semibold)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.Fills.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(Color.Colors.green1)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }
                    .disabled(viewModel.isSubmitting)
                    
                }
                
            }
            .onAppear {
                viewModel.calculateRecommendedPagesPerDay(
                    startPage: startPage,
                    targetEndPage: totalPages,
                    startDate: startDate,
                    endDate: endDate,
                    excludedDays: bookSettingInputModel.nonReadingDays
                )
            }
            .onAppear {
                // GA4 Tracking
                Tracking.Screen.registrationResult.setTracking()
            }
        }
        
    }

    @MainActor
    private func registerBook(
        selectedBook: Book,
        startPage: Int,
        targetEndPage: Int,
        startDate: Date,
        endDate: Date
    ) async {
        let registered = await viewModel.registerBook(
            selectedBook: selectedBook,
            startPage: startPage,
            targetEndPage: targetEndPage,
            startDate: startDate,
            endDate: endDate,
            excludedReadingDays: bookSettingInputModel.nonReadingDays
        )

        if registered {
            navigationCoordinator.popToRoot()
        }
    }
}

struct TextView: View {
    var text: String
    
    var body: some View {
        Text(text)
            .fontStyle(.title1, weight: .semibold)
    }
}

#Preview("완독 목표 요약") {
    let inputModel = PreviewSupport.makeBookSettingInputModel()

    return NavigationStack {
        FinishGoalView(
            viewModel: FinishGoalViewModel(
                bookManagementService: PreviewBookManagementService()
            )
        )
    }
    .environment(PreviewSupport.makeCoordinator())
    .environment(inputModel)
}

#Preview("입력 누락 상태") {
    let inputModel = BookSettingInputModel()

    return NavigationStack {
        FinishGoalView(
            viewModel: FinishGoalViewModel(
                bookManagementService: PreviewBookManagementService()
            )
        )
    }
    .environment(PreviewSupport.makeCoordinator())
    .environment(inputModel)
}
